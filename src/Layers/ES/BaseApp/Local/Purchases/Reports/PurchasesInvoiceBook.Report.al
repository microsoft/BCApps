// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 10705 "Purchases Invoice Book"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/PurchasesInvoiceBook.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Purchases Invoice Book';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("<Integer3>"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(USERID; UserId)
            {
            }
            column(CompanyAddr_7_; CompanyAddr[7])
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
            column(CompanyAddr_3_; CompanyAddr[3])
            {
            }
            column(CompanyAddr_2_; CompanyAddr[2])
            {
            }
            column(CompanyAddr_1_; CompanyAddr[1])
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(SortPostDate; SortPostDate)
            {
            }
            column(SortVATDate; SortVATDate)
            {
            }
            column(PrintAmountsInAddCurrency; PrintAmountsInAddCurrency)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(AuxVatEntry; AuxVatEntry)
            {
            }
            column(Integer3__Number; Number)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Purchases_Invoice_BookCaption; Purchases_Invoice_BookCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(EC_Caption; EC_CaptionLbl)
            {
            }
            column(VAT_Caption; VAT_CaptionLbl)
            {
            }
            column(BaseCaption; BaseCaptionLbl)
            {
            }
            column(VAT_RegistrationCaption; VAT_RegistrationCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(External_Document_No_Caption; External_Document_No_CaptionLbl)
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            column(VAT_DateCaption; VAT_DateCaptionLbl)
            {
            }
            column(Document_DateCaption; Document_DateCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(Epedition_DateCaption; Epedition_DateCaptionLbl)
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
            dataitem(VATEntry; "VAT Entry")
            {
                DataItemTableView = sorting("No. Series", "VAT Reporting Date") where(Type = const(Purchase));
                RequestFilterFields = "VAT Reporting Date", "Document Date", "Document Type", "Document No.";
                column(Base_TotalBaseImport; Base - TotalBaseImport)
                {
                }
                column(AmountVatReverse3; AmountVatReverse3)
                {
                }
                column(Base_AmountVatReverse3; Base + AmountVatReverse3)
                {
                }
                column(Additional_Currency_Base__TotalBaseImport; "Additional-Currency Base" - TotalBaseImport)
                {
                }
                column(AmountVatReverse3_Control30; AmountVatReverse3)
                {
                }
                column(Additional_Currency_Base__AmountVatReverse3; "Additional-Currency Base" + AmountVatReverse3)
                {
                }
                column(Base_Base2__TotalBaseImport; (Base + Base2) - TotalBaseImport)
                {
                }
                column(AmountVatReverse3_Amount2; AmountVatReverse3 + Amount2)
                {
                }
                column(Base_Base2___AmountVatReverse3_Amount2_; (Base + Base2) + (AmountVatReverse3 + Amount2))
                {
                }
                column(Additional_Currency_Base__Base2__TotalBaseImport; ("Additional-Currency Base" + Base2) - TotalBaseImport)
                {
                }
                column(AmountVatReverse3___Amount2; AmountVatReverse3 + Amount2)
                {
                }
                column(Additional_Currency_Base__Base2___AmountVatReverse3_Amount2_; ("Additional-Currency Base" + Base2) + (AmountVatReverse3 + Amount2))
                {
                }
                column(VATEntry__No__Series_; "No. Series")
                {
                }
                column(Base_AmountVatReverse; Base + AmountVatReverse)
                {
                }
                column(AmountVatReverse; AmountVatReverse)
                {
                }
                column(Base_TotalBaseImport_Control74; Base - TotalBaseImport)
                {
                }
                column(VATEntry__No__Series__Control75; "No. Series")
                {
                }
                column(VATEntry__No__Series__Control80; "No. Series")
                {
                }
                column(Additional_Currency_Base__TotalBaseImport_Control84; "Additional-Currency Base" - TotalBaseImport)
                {
                }
                column(AmountVatReverse_Control85; AmountVatReverse)
                {
                }
                column(Additional_Currency_Base__AmountVatReverse; "Additional-Currency Base" + AmountVatReverse)
                {
                }
                column(Base_TotalBaseImport_Control23; Base - TotalBaseImport)
                {
                }
                column(AmountVatReverse3_Control40; AmountVatReverse3)
                {
                }
                column(Base_AmountVatReverse3_Control65; Base + AmountVatReverse3)
                {
                }
                column(Additional_Currency_Base__TotalBaseImport_Control33; "Additional-Currency Base" - TotalBaseImport)
                {
                }
                column(AmountVatReverse3_Control34; AmountVatReverse3)
                {
                }
                column(Additional_Currency_Base__AmountVatReverse3_Control35; "Additional-Currency Base" + AmountVatReverse3)
                {
                }
                column(Base_Base2__TotalBaseImport_Control131; (Base + Base2) - TotalBaseImport)
                {
                }
                column(AmountVatReverse3_Amount2_Control132; AmountVatReverse3 + Amount2)
                {
                }
                column(Base_Base2___AmountVatReverse3_Amount2__Control133; (Base + Base2) + (AmountVatReverse3 + Amount2))
                {
                }
                column(Additional_Currency_Base__TotalBaseImport_Control135; "Additional-Currency Base" - TotalBaseImport)
                {
                }
                column(AmountVatReverse3_Control136; AmountVatReverse3)
                {
                }
                column(Additional_Currency_Base__AmountVatReverse3_Control137; "Additional-Currency Base" + AmountVatReverse3)
                {
                }
                column(Base_Base2__TotalBaseImport_Control57; (Base + Base2) - TotalBaseImport)
                {
                }
                column(AmountVatReverse_Amount2; AmountVatReverse + Amount2)
                {
                }
                column(Base_Base2___AmountVatReverse_Amount2_; (Base + Base2) + (AmountVatReverse + Amount2))
                {
                }
                column(Additional_Currency_Base__Base2__TotalBaseImport_Control124; ("Additional-Currency Base" + Base2) - TotalBaseImport)
                {
                }
                column(AmountVatReverse___Amount2; AmountVatReverse + Amount2)
                {
                }
                column(Additional_Currency_Base__Base2___AmountVatReverse_Amount2_; ("Additional-Currency Base" + Base2) + (AmountVatReverse + Amount2))
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
                column(VATEntry_VAT_Date; "VAT Reporting Date")
                {
                }
                column(VATEntry_Document_Type; "Document Type")
                {
                }
                column(VATEntry_Document_No_; "Document No.")
                {
                }
                column(ContinuedCaption; ContinuedCaptionLbl)
                {
                }
                column(ContinuedCaption_Control28; ContinuedCaption_Control28Lbl)
                {
                }
                column(ContinuedCaption_Control48; ContinuedCaption_Control48Lbl)
                {
                }
                column(ContinuedCaption_Control49; ContinuedCaption_Control49Lbl)
                {
                }
                column(VATEntry__No__Series_Caption; FieldCaption("No. Series"))
                {
                }
                column(VATEntry__No__Series__Control75Caption; FieldCaption("No. Series"))
                {
                }
                column(TotalCaption_Control77; TotalCaption_Control77Lbl)
                {
                }
                column(TotalCaption_Control78; TotalCaption_Control78Lbl)
                {
                }
                column(VATEntry__No__Series__Control80Caption; FieldCaption("No. Series"))
                {
                }
                column(ContinuedCaption_Control18; ContinuedCaption_Control18Lbl)
                {
                }
                column(ContinuedCaption_Control32; ContinuedCaption_Control32Lbl)
                {
                }
                column(ContinuedCaption_Control130; ContinuedCaption_Control130Lbl)
                {
                }
                column(ContinuedCaption_Control134; ContinuedCaption_Control134Lbl)
                {
                }
                column(TotalCaption_Control54; TotalCaption_Control54Lbl)
                {
                }
                column(TotalCaption_Control127; TotalCaption_Control127Lbl)
                {
                }
                dataitem(VATEntry6; "VAT Entry")
                {
                    DataItemTableView = sorting(Type, "VAT Reporting Date", "Document Type", "Document No.", "Bill-to/Pay-to No.") where(Type = const(Purchase));
                    column(VATEntry6_Entry_No_; "Entry No.")
                    {
                    }
                    column(VATEntry6_Type; Type)
                    {
                    }
                    column(VATEntry6_Posting_Date; "Posting Date")
                    {
                    }
                    column(VATEntry6_VAT_Date; "VAT Reporting Date")
                    {
                    }
                    column(VATEntry6_Document_Date; "Document Date")
                    {
                    }
                    column(VATEntry6_Document_Type; "Document Type")
                    {
                    }
                    column(VATEntry6_Document_No_; "Document No.")
                    {
                    }
                    dataitem(VATEntry7; "VAT Entry")
                    {
                        DataItemLink = Type = field(Type), "VAT Reporting Date" = field("VAT Reporting Date"), "Document Type" = field("Document Type"), "Document No." = field("Document No.");
                        DataItemTableView = sorting(Type, "VAT Reporting Date", "Document Type", "Document No.", "Bill-to/Pay-to No.");

                        trigger OnAfterGetRecord()
                        begin
                            VATBuffer3."VAT %" := "VAT %";
                            VATBuffer3."EC %" := "EC %";
                            if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then
                                if not PrintAmountsInAddCurrency then
                                    if VATBuffer3.Find() then begin
                                        VATBuffer3.Base := VATBuffer3.Base + Base;
                                        VATBuffer3.Amount := VATBuffer3.Amount + Amount;
                                        VATBuffer3."Non-Deductible VAT Base" := VATBuffer3."Non-Deductible VAT Base" + "Non-Deductible VAT Base";
                                        VATBuffer3."Non-Deductible VAT Amount" := VATBuffer3."Non-Deductible VAT Amount" + "Non-Deductible VAT Amount";
                                        VATBuffer3.Modify();
                                    end else begin
                                        VATBuffer3.Base := Base;
                                        VATBuffer3.Amount := Amount;
                                        VATBuffer3."Non-Deductible VAT Base" := "Non-Deductible VAT Base";
                                        VATBuffer3."Non-Deductible VAT Amount" := "Non-Deductible VAT Amount";
                                        VATBuffer3.Insert();
                                    end
                                else
                                    if VATBuffer3.Find() then begin
                                        VATBuffer3.Base := VATBuffer3.Base + "Additional-Currency Base";
                                        VATBuffer3.Amount := VATBuffer3.Amount + "Additional-Currency Amount";
                                        VATBuffer3."Non-Deductible VAT Base" := VATBuffer3."Non-Deductible VAT Base" + "Non-Deductible VAT Base ACY";
                                        VATBuffer3."Non-Deductible VAT Amount" := VATBuffer3."Non-Deductible VAT Amount" + "Non-Deductible VAT Amount ACY";
                                        VATBuffer3.Modify();
                                    end else begin
                                        VATBuffer3.Base := "Additional-Currency Base";
                                        VATBuffer3.Amount := "Additional-Currency Amount";
                                        VATBuffer3."Non-Deductible VAT Base" := "Non-Deductible VAT Base ACY";
                                        VATBuffer3."Non-Deductible VAT Amount" := "Non-Deductible VAT Amount ACY";
                                        VATBuffer3.Insert();
                                    end;

                            if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then begin
                                NotBaseReverse := NotBaseReverse + VATBuffer3.Base;
                                NotAmountReverse := NotAmountReverse + VATBuffer3.Amount;
                            end;
                        end;

                        trigger OnPostDataItem()
                        begin
                            VATEntry6 := VATEntry7;
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(PurchCrMemoHeader);
                            Clear(PurchInvHeader);
                            Clear(Vendor);
                            PurchInvHeader.Reset();
                            PurchCrMemoHeader.Reset();
                            Vendor.Reset();
                            VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
                            case VATEntry6."Document Type" of
                                "Document Type"::"Credit Memo":
                                    if PurchCrMemoHeader.Get(VATEntry6."Document No.") then begin
                                        Vendor.Name := PurchCrMemoHeader."Pay-to Name";
                                        Vendor."VAT Registration No." := PurchCrMemoHeader."VAT Registration No.";
                                        VendLedgEntry.SetRange("Document No.", VATEntry6."Document No.");
                                        VendLedgEntry.SetRange("Document Type", "Document Type"::"Credit Memo");
                                        if VendLedgEntry.FindFirst() then
                                            AutoDocNo := VendLedgEntry."Autodocument No.";
                                        exit;
                                    end;
                                "Document Type"::Invoice:
                                    if PurchInvHeader.Get(VATEntry6."Document No.") then begin
                                        Vendor.Name := PurchInvHeader."Pay-to Name";
                                        Vendor."VAT Registration No." := PurchInvHeader."VAT Registration No.";
                                        VendLedgEntry.SetRange("Document No.", VATEntry6."Document No.");
                                        VendLedgEntry.SetRange("Document Type", "Document Type"::Invoice);
                                        if VendLedgEntry.FindFirst() then
                                            AutoDocNo := VendLedgEntry."Autodocument No.";
                                        exit;
                                    end;
                            end;

                            if not Vendor.Get(VATEntry6."Bill-to/Pay-to No.") then
                                Vendor.Name := Text1100003;
                            VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
                            VendLedgEntry.SetRange("Document No.", VATEntry6."Document No.");
                            VendLedgEntry.SetFilter("Document Type", Text1100004);
                            if VendLedgEntry.FindFirst() then;
                        end;
                    }
                    dataitem("<Integer4>"; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATBuffer4_Base_VATBuffer4_Amount; VATBuffer4.Base + VATBuffer4.Amount)
                        {
                        }
                        column(VATBuffer4_Amount; VATBuffer4.Amount)
                        {
                        }
                        column(VATBuffer4_Base; VATBuffer4.Base)
                        {
                        }
                        column(CompanyInfo_Name; CompanyInfo.Name)
                        {
                        }
                        column(VATEntry7__Document_No__; VATEntry7."Document No.")
                        {
                        }
                        column(VATEntry7__Posting_Date_; Format(VATEntry7."Posting Date"))
                        {
                        }
                        column(VATEntry7__VAT_Date_; Format(VATEntry7."VAT Reporting Date"))
                        {
                        }
                        column(VATEntry7__Document_Date_; Format(VATEntry7."Document Date"))
                        {
                        }
                        column(AutoDocNo; AutoDocNo)
                        {
                        }
                        column(DocType; DocType)
                        {
                        }
                        column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                        {
                        }
                        column(VATBuffer4__VAT___; VATBuffer4."VAT %")
                        {
                        }
                        column(VATBuffer4__EC___; VATBuffer4."EC %")
                        {
                        }
                        column(FORMAT_VATEntry7__Document_Date__; Format(VATEntry7."Document Date"))
                        {
                        }
                        column(VATBuffer4_Base_VATBuffer4_Amount_Control43; VATBuffer4.Base + VATBuffer4.Amount)
                        {
                        }
                        column(VATBuffer4_Amount_Control44; VATBuffer4.Amount)
                        {
                        }
                        column(VATBuffer4_Base_Control47; VATBuffer4.Base)
                        {
                        }
                        column(VATBuffer4__VAT____Control10; VATBuffer4."VAT %")
                        {
                        }
                        column(VATBuffer4__EC____Control19; VATBuffer4."EC %")
                        {
                        }
                        column(Integer4__Number; Number)
                        {
                        }
                        column(VATEntry7_NonDeductibleVAT; VATEntry7."Non-Deductible VAT %")
                        {
                        }
                        column(VATEntry7_NonDeductibleVATBase; VATEntry7."Non-Deductible VAT Base")
                        {
                        }
                        column(VATEntry7_NonDeductibleVATAmt; VATEntry7."Non-Deductible VAT Amount")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Fin then
                                CurrReport.Break();
                            VATBuffer4 := VATBuffer3;
                            Fin := VATBuffer3.Next() = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            VATBuffer3.Find('-');
                            Fin := false;
                            LineNo := 0;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not Show then
                            CurrReport.Break();
                        VATBuffer3.DeleteAll();
                        NoSeriesAuxPrev := NoSeriesAux;
                        if "Document Type" = "Document Type"::"Credit Memo" then begin
                            GLSetup.Get();
                            NoSeriesAux := GLSetup."Autocredit Memo Nos.";
                        end;
                        if "Document Type" = "Document Type"::Invoice then begin
                            GLSetup.Get();
                            NoSeriesAux := GLSetup."Autoinvoice Nos.";
                        end;
                        if NoSeriesAux <> NoSeriesAuxPrev then begin
                            NotBaseReverse := 0;
                            NotAmountReverse := 0;
                        end;
                    end;

                    trigger OnPostDataItem()
                    begin
                        PrevData := VATEntry."VAT Reporting Date" + 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not SortVATDate or not ShowAutoInvCred then
                            CurrReport.Break();

                        SetRange("Generated Autodocument", true);
                        if Find('-') then;
                        if i = 1 then begin
                            repeat
                                VatEntryTemporary.Init();
                                VatEntryTemporary.Copy(VATEntry6);
                                VatEntryTemporary.Insert();
                                VatEntryTemporary.Next();
                            until Next() = 0;
                            if Find('-') then;
                            i := 0;
                        end;
                        SetFilter("VAT Reporting Date", '%1..%2', PrevData, VATEntry."VAT Reporting Date");
                        SetFilter("Document No.", VATEntry.GetFilter("Document No."));
                        SetFilter("Document Type", VATEntry.GetFilter("Document Type"));
                        if VatEntryTemporary.Find('-') then;
                        VatEntryTemporary.SetRange("Generated Autodocument", true);
                        VatEntryTemporary.SetFilter("VAT Reporting Date", '%1..%2', PrevData, VATEntry."VAT Reporting Date");
                        if VatEntryTemporary.Find('-') then begin
                            Show := true;
                            VatEntryTemporary.DeleteAll();
                        end else
                            Show := false;
                    end;
                }
                dataitem(VATEntry2; "VAT Entry")
                {
                    DataItemLink = Type = field(Type), "VAT Reporting Date" = field("VAT Reporting Date"), "Document Type" = field("Document Type"), "Document No." = field("Document No."), "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"), "Gen. Prod. Posting Group" = field("Gen. Prod. Posting Group");
                    DataItemTableView = sorting("No. Series", "VAT Reporting Date");

                    trigger OnAfterGetRecord()
                    begin
                        if ShowAutoInvCred and ("VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT") then begin
                            VATBuffer."VAT %" := 0;
                            VATBuffer."EC %" := 0;
                            VATBuffer."Non-Deductible VAT %" := 0;
                        end else begin
                            VATBuffer."VAT %" := "VAT %";
                            VATBuffer."EC %" := "EC %";
                            VATBuffer."Non-Deductible VAT %" := "Non-Deductible VAT %";
                        end;
                        if not PrintAmountsInAddCurrency then begin
                            if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                                Base := 0;
                            if VATBuffer.Find() then begin
                                VATBuffer.Base := VATBuffer.Base + Base;
                                VATBuffer."Non-Deductible VAT Base" := VATBuffer."Non-Deductible VAT Base" + "Non-Deductible VAT Base";
                                if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                                    BaseImport := BaseImport + Base;
                                if (not ShowAutoInvCred) or ("VAT Calculation Type" <> "VAT Calculation Type"::"Reverse Charge VAT") then begin
                                    VATBuffer.Amount := VATBuffer.Amount + Amount;
                                    VATBuffer."Non-Deductible VAT Amount" := VATBuffer."Non-Deductible VAT Amount" + "Non-Deductible VAT Amount";
                                    AmountVatReverse := AmountVatReverse + Amount;
                                end;
                                VATBuffer.Modify();
                            end else begin
                                VATBuffer.Base := Base;
                                VATBuffer."Non-Deductible VAT Base" := "Non-Deductible VAT Base";
                                if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                                    BaseImport := Base;
                                if (not ShowAutoInvCred) or ("VAT Calculation Type" <> "VAT Calculation Type"::"Reverse Charge VAT") then begin
                                    VATBuffer.Amount := Amount;
                                    VATBuffer."Non-Deductible VAT Amount" := "Non-Deductible VAT Amount";
                                    AmountVatReverse := AmountVatReverse + Amount;
                                end else begin
                                    VATBuffer.Amount := 0;
                                    VATBuffer."Non-Deductible VAT Amount" := 0;
                                end;
                                VATBuffer.Insert();
                            end;
                        end else begin
                            if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                                "Additional-Currency Base" := 0;
                            if VATBuffer.Find() then begin
                                VATBuffer.Base := VATBuffer.Base + "Additional-Currency Base";
                                VATBuffer."Non-Deductible VAT Base" := VATBuffer."Non-Deductible VAT Base" + "Non-Deductible VAT Base ACY";
                                if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                                    BaseImport := BaseImport + "Additional-Currency Base";
                                if (not ShowAutoInvCred) or ("VAT Calculation Type" <> "VAT Calculation Type"::"Reverse Charge VAT") then begin
                                    VATBuffer.Amount := VATBuffer.Amount + "Additional-Currency Amount";
                                    VATBuffer."Non-Deductible VAT Amount" := VATBuffer."Non-Deductible VAT Amount" + "Non-Deductible VAT Amount ACY";
                                    AmountVatReverse := AmountVatReverse + "Additional-Currency Amount";
                                end;
                                VATBuffer.Modify();
                            end else begin
                                VATBuffer.Base := "Additional-Currency Base";
                                VATBuffer."Non-Deductible VAT Base" := "Non-Deductible VAT Base ACY";
                                if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                                    BaseImport := "Additional-Currency Base";
                                if (not ShowAutoInvCred) or ("VAT Calculation Type" <> "VAT Calculation Type"::"Reverse Charge VAT") then begin
                                    VATBuffer.Amount := "Additional-Currency Amount";
                                    VATBuffer."Non-Deductible VAT Amount" := "Non-Deductible VAT Amount ACY";
                                    AmountVatReverse := AmountVatReverse + "Additional-Currency Amount";
                                end else begin
                                    VATBuffer.Amount := 0;
                                    VATBuffer."Non-Deductible VAT Amount" := 0;
                                end;
                                VATBuffer.Insert();
                            end;
                        end;
                        if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                            TotalBaseImport := TotalBaseImport + BaseImport;
                        TempVATEntry := VATEntry2;
                        if not TempVATEntry.Find() then
                            TempVATEntry.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if SortVATDate then
                            SetCurrentKey(Type, "VAT Reporting Date", "Document Type", "Document No.", "Bill-to/Pay-to No.")
                        else
                            SetCurrentKey("No. Series", "VAT Reporting Date");

                        SetRange("No. Series", VATEntry."No. Series");
                        Clear(PurchCrMemoHeader);
                        Clear(PurchInvHeader);
                        Clear(Vendor);

                        if not PrintAmountsInAddCurrency then
                            GLSetup.Get()
                        else begin
                            GLSetup.Get();
                            Currency.Get(GLSetup."Additional Reporting Currency");
                        end;
                        case VATEntry."Document Type" of
                            "Document Type"::"Credit Memo":
                                if PurchCrMemoHeader.Get(VATEntry."Document No.") then begin
                                    Vendor.Name := PurchCrMemoHeader."Pay-to Name";
                                    Vendor."VAT Registration No." := PurchCrMemoHeader."VAT Registration No.";
                                    exit;
                                end;
                            "Document Type"::Invoice:
                                if PurchInvHeader.Get(VATEntry."Document No.") then begin
                                    Vendor.Name := PurchInvHeader."Pay-to Name";
                                    Vendor."VAT Registration No." := PurchInvHeader."VAT Registration No.";
                                    exit;
                                end;
                        end;

                        if not Vendor.Get(VATEntry."Bill-to/Pay-to No.") then
                            Vendor.Name := Text1100003;
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
                    column(VATEntry2__Posting_Date_; Format(VATEntry2."Posting Date"))
                    {
                    }
                    column(VATEntry2__VAT_Date_; Format(VATEntry2."VAT Reporting Date"))
                    {
                    }
                    column(VATEntry2__Document_Date_; Format(VATEntry2."Document Date"))
                    {
                    }
                    column(Vendor_Name; Vendor.Name)
                    {
                    }
                    column(DocType_Control11; DocType)
                    {
                    }
                    column(VATBuffer2_Amount; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_VATBuffer2_Amount; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(VATEntry2__External_Document_No__; VATEntry2."External Document No.")
                    {
                    }
                    column(Vendor__VAT_Registration_No__; Vendor."VAT Registration No.")
                    {
                    }
                    column(VATBuffer2__VAT___; VATBuffer2."VAT %")
                    {
                    }
                    column(VATBuffer2__EC___; VATBuffer2."EC %")
                    {
                    }
                    column(FORMAT_VATEntry2__Document_Date__; Format(VATEntry2."Document Date"))
                    {
                    }
                    column(VATBuffer2_Base_VATBuffer2_Amount_Control53; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Amount_Control58; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_Control61; VATBuffer2.Base)
                    {
                    }
                    column(VATBuffer2__VAT____Control59; VATBuffer2."VAT %")
                    {
                    }
                    column(VATBuffer2__EC____Control60; VATBuffer2."EC %")
                    {
                    }
                    column(VATBuffer2_Base_Control62; VATBuffer2.Base)
                    {
                    }
                    column(VATBuffer2_Amount_Control63; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_VATBuffer2_Amount_Control64; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(Integer_Number; Number)
                    {
                    }
                    column(TotalCaption_Control26; TotalCaption_Control26Lbl)
                    {
                    }
                    column(VATEntry2_NonDeductibleVAT; VATBuffer2."Non-Deductible VAT %")
                    {
                    }
                    column(VATEntry2_NonDeductibleVATBase; VATBuffer2."Non-Deductible VAT Base")
                    {
                    }
                    column(VATEntry2_NonDeductibleVATAmt; VATBuffer2."Non-Deductible VAT Amount")
                    {
                    }
                    column(VATEntry2_TotalAmount; VATBuffer2.Base + VATBuffer2.Amount + VATBuffer2."Non-Deductible VAT Base" + VATBuffer2."Non-Deductible VAT Amount")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Fin then
                            CurrReport.Break();
                        VATBuffer2 := VATBuffer;
                        Fin := VATBuffer.Next() = 0;
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
                    TempVATEntry := VATEntry;
                    if TempVATEntry.Find() then
                        CurrReport.Skip();
                    AmountVatReverse3 := AmountVatReverse;

                    DocType := Format("Document Type");
                    if "Document Type" = "Document Type"::"Credit Memo" then
                        DocType := Text1100005;
                end;

                trigger OnPreDataItem()
                begin
                    if GetFilter("VAT Reporting Date") = '' then
                        PrevData := 0D
                    else
                        PrevData := GetRangeMin("VAT Reporting Date");
                    i := 1;
                    if SortVATDate then
                        SetCurrentKey(Type, "VAT Reporting Date", "Document Type", "Document No.", "Bill-to/Pay-to No.")
                    else
                        SetCurrentKey("No. Series", "VAT Reporting Date", "Document No.");
                    if OnlyIncludeSIIDocuments then
                        SetRange("Do Not Send To SII", false);
                    TempVATEntry.Reset();
                    TempVATEntry.DeleteAll();
                end;
            }
            dataitem(VATEntry3; "VAT Entry")
            {
                DataItemTableView = sorting("Document Type", "No. Series", "VAT Reporting Date") where(Type = const(Purchase));
                column(VarNotAmountReverse; VarNotAmountReverse)
                {
                }
                column(VarNotBaseReverse; VarNotBaseReverse)
                {
                }
                column(VarNotBaseReverse_VarNotAmountReverse; VarNotBaseReverse + VarNotAmountReverse)
                {
                }
                column(No_SeriesAux_; NoSeriesAux)
                {
                }
                column(No_SeriesAux__Control107; NoSeriesAux)
                {
                }
                column(NotBaseReverse; NotBaseReverse)
                {
                }
                column(NotAmountReverse; NotAmountReverse)
                {
                }
                column(NotBaseReverse_NotAmountReverse; NotBaseReverse + NotAmountReverse)
                {
                }
                column(VarNotBaseReverse_Control120; VarNotBaseReverse)
                {
                }
                column(VarNotAmountReverse_Control156; VarNotAmountReverse)
                {
                }
                column(VarNotBaseReverse_VarNotAmountReverse_Control159; VarNotBaseReverse + VarNotAmountReverse)
                {
                }
                column(VATEntry3_Entry_No_; "Entry No.")
                {
                }
                column(VATEntry3_Document_Type; "Document Type")
                {
                }
                column(VATEntry3_Type; Type)
                {
                }
                column(VATEntry3_Posting_Date; "Posting Date")
                {
                }
                column(VATEntry3_VAT_Date; "VAT Reporting Date")
                {
                }
                column(VATEntry3_Document_No_; "Document No.")
                {
                }
                column(ContinuedCaption_Control103; ContinuedCaption_Control103Lbl)
                {
                }
                column(No_SerieCaption; No_SerieCaptionLbl)
                {
                }
                column(TotalCaption_Control96; TotalCaption_Control96Lbl)
                {
                }
                column(No_SerieCaption_Control97; No_SerieCaption_Control97Lbl)
                {
                }
                column(ContinuedCaption_Control119; ContinuedCaption_Control119Lbl)
                {
                }
                dataitem(VATEntry4; "VAT Entry")
                {
                    DataItemLink = Type = field(Type), "VAT Reporting Date" = field("VAT Reporting Date"), "Document Type" = field("Document Type"), "Document No." = field("Document No.");
                    DataItemTableView = sorting("No. Series", "VAT Reporting Date");
                    column(VATEntry4_Type; Type)
                    {
                    }
                    column(VATEntry4_Entry_No_; "Entry No.")
                    {
                    }
                    column(VATEntry4_Posting_Date; "Posting Date")
                    {
                    }
                    column(VATEntry4_VAT_Date; "VAT Reporting Date")
                    {
                    }
                    column(VATEntry4_Document_Date; "Document Date")
                    {
                    }
                    column(VATEntry4_Document_Type; "Document Type")
                    {
                    }
                    column(VATEntry4_Document_No_; "Document No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        VATBuffer."VAT %" := "VAT %";
                        VATBuffer."EC %" := "EC %";
                        VATBuffer."Non-Deductible VAT %" := "Non-Deductible VAT %";
                        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then
                            if not PrintAmountsInAddCurrency then
                                if VATBuffer.Find() then begin
                                    VarBase2 := (VATBuffer.Base + Base) - VATBuffer.Base;
                                    VarAmount2 := (VATBuffer.Amount + Amount) - VATBuffer.Amount;
                                    VATBuffer.Base := VATBuffer.Base + Base;
                                    VATBuffer.Amount := VATBuffer.Amount + Amount;
                                    VATBuffer.Modify();
                                end else begin
                                    VarBase2 := Base;
                                    VarAmount2 := Amount;
                                    VATBuffer.Base := Base;
                                    VATBuffer.Amount := Amount;
                                    VATBuffer.Insert();
                                end
                            else
                                if VATBuffer.Find() then begin
                                    VATBuffer.Base := VATBuffer.Base + "Additional-Currency Base";
                                    VATBuffer.Amount := VATBuffer.Amount + "Additional-Currency Amount";
                                    VATBuffer.Modify();
                                end else begin
                                    VATBuffer.Base := "Additional-Currency Base";
                                    VATBuffer.Amount := "Additional-Currency Amount";
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
                        VATEntry3 := VATEntry4;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(PurchCrMemoHeader);
                        Clear(PurchInvHeader);
                        Clear(Vendor);
                        PurchInvHeader.Reset();
                        PurchCrMemoHeader.Reset();
                        Vendor.Reset();

                        VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
                        case VATEntry3."Document Type" of
                            "Document Type"::"Credit Memo":
                                if PurchCrMemoHeader.Get(VATEntry3."Document No.") then begin
                                    Vendor.Name := PurchCrMemoHeader."Pay-to Name";
                                    Vendor."VAT Registration No." := PurchCrMemoHeader."VAT Registration No.";
                                    VendLedgEntry.SetRange("Document No.", VATEntry3."Document No.");
                                    VendLedgEntry.SetRange("Document Type", "Document Type"::"Credit Memo");
                                    if VendLedgEntry.FindFirst() then
                                        AutoDocNo := VendLedgEntry."Autodocument No.";
                                    exit;
                                end;
                            "Document Type"::Invoice:
                                if PurchInvHeader.Get(VATEntry3."Document No.") then begin
                                    Vendor.Name := PurchInvHeader."Pay-to Name";
                                    Vendor."VAT Registration No." := PurchInvHeader."VAT Registration No.";
                                    VendLedgEntry.SetRange("Document No.", VATEntry3."Document No.");
                                    VendLedgEntry.SetRange("Document Type", "Document Type"::Invoice);
                                    if VendLedgEntry.FindFirst() then
                                        AutoDocNo := VendLedgEntry."Autodocument No.";
                                    exit;
                                end;
                        end;

                        if not Vendor.Get(VATEntry3."Bill-to/Pay-to No.") then
                            Vendor.Name := Text1100003;
                        VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
                        VendLedgEntry.SetRange("Document No.", VATEntry3."Document No.");
                        VendLedgEntry.SetFilter("Document Type", Text1100004);
                        if VendLedgEntry.FindFirst() then;
                    end;
                }
                dataitem("<Integer2>"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VATBuffer2_Base_VATBuffer2_Amount_Control81; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Amount_Control82; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2__EC____Control83; VATBuffer2."EC %")
                    {
                    }
                    column(VATBuffer2__VAT____Control87; VATBuffer2."VAT %")
                    {
                    }
                    column(VATBuffer2_Base_Control88; VATBuffer2.Base)
                    {
                    }
                    column(CompanyInfo__VAT_Registration_No___Control89; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfo_Name_Control90; CompanyInfo.Name)
                    {
                    }
                    column(VATEntry4__Document_No__; VATEntry4."Document No.")
                    {
                    }
                    column(VATEntry4__Document_Type_; VATEntry4."Document Type")
                    {
                    }
                    column(AutoDocNo_Control93; AutoDocNo)
                    {
                    }
                    column(VATEntry4__Posting_Date_; Format(VATEntry4."Posting Date"))
                    {
                    }
                    column(VATEntry4__VAT_Date_; Format(VATEntry4."VAT Reporting Date"))
                    {
                    }
                    column(FORMAT_VATEntry4__Document_Date__; Format(VATEntry4."Document Date"))
                    {
                    }
                    column(VATBuffer2_Base_Control98; VATBuffer2.Base)
                    {
                    }
                    column(VATBuffer2__VAT____Control99; VATBuffer2."VAT %")
                    {
                    }
                    column(VATBuffer2__EC____Control100; VATBuffer2."EC %")
                    {
                    }
                    column(VATBuffer2_Amount_Control101; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_VATBuffer2_Amount_Control102; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_Control22; VATBuffer2.Base)
                    {
                    }
                    column(VATBuffer2_Amount_Control24; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_VATBuffer2_Amount_Control27; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(Integer2__Number; Number)
                    {
                    }
                    column(TotalCaption_Control21; TotalCaption_Control21Lbl)
                    {
                    }
                    column(VATEntry4_NonDeductibleVAT; VATEntry4."Non-Deductible VAT %")
                    {
                    }
                    column(VATEntry4_NonDeductibleVATBase; VATEntry4."Non-Deductible VAT Base")
                    {
                    }
                    column(VATEntry4_NonDeductibleVATAmt; VATEntry4."Non-Deductible VAT Amount")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Fin then
                            CurrReport.Break();
                        VATBuffer2 := VATBuffer;
                        Fin := VATBuffer.Next() = 0;
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
                    if "Document Type" = "Document Type"::"Credit Memo" then begin
                        GLSetup.Get();
                        NoSeriesAux := GLSetup."Autocredit Memo Nos.";
                    end;
                    if "Document Type" = "Document Type"::Invoice then begin
                        GLSetup.Get();
                        NoSeriesAux := GLSetup."Autoinvoice Nos.";
                    end;
                    if NoSeriesAux <> NoSeriesAuxPrev then begin
                        NotBaseReverse := 0;
                        NotAmountReverse := 0;
                        VarNotBaseReverse := 0;
                        VarNotAmountReverse := 0;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if SortVATDate or not ShowAutoInvCred then
                        CurrReport.Break();

                    SetRange("Generated Autodocument", true);
                    if Find('-') then;
                    SetFilter("VAT Reporting Date", VATEntry.GetFilter("VAT Reporting Date"));
                    SetFilter("Document No.", VATEntry.GetFilter("Document No."));
                    SetFilter("Document Type", VATEntry.GetFilter("Document Type"));
                    NotBaseReverse := 0;
                    NotAmountReverse := 0;
                end;
            }
            dataitem("No Taxable Entry"; "No Taxable Entry")
            {
                DataItemTableView = sorting("Entry No.") where(Type = const(Purchase), Reversed = const(false), "Not In 347" = const(false));
                RequestFilterFields = "VAT Reporting Date", "Document Type", "Document No.";
                column(PostingDate_NoTaxableEntry; Format("Posting Date"))
                {
                }
                column(VATDate_NoTaxableEntry; Format("VAT Reporting Date"))
                {
                }
                column(DocumentNo_NoTaxableEntry; "Document No.")
                {
                }
                column(DocumentType_NoTaxableEntry; "Document Type")
                {
                }
                column(Type_NoTaxableEntry; Type)
                {
                }
                column(Base_NoTaxableEntry; NoTaxableAmount)
                {
                }
                column(SourceNo_NoTaxableEntry; "Source No.")
                {
                }
                column(SourceName_NoTaxableEntry; Vendor.Name)
                {
                }
                column(ExternalDocumentNo_NoTaxableEntry; "External Document No.")
                {
                }
                column(NoSeriesCaption_NoTaxableEntry; FieldCaption("No. Series"))
                {
                }
                column(NoSeries_NoTaxableEntry; "No. Series")
                {
                }
                column(DocumentDate_NoTaxableEntry; Format("Document Date"))
                {
                }
                column(DocumentDateFormat_NoTaxableEntry; Format("Document Date"))
                {
                }
                column(VATRegistrationNo_NoTaxableEntry; "VAT Registration No.")
                {
                }
                column(NoTaxableTitleText; NoTaxableText)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not Vendor.Get("Source No.") then
                        Vendor.Name := Text1100003;
                    if PrintAmountsInAddCurrency then
                        NoTaxableAmount := "Base (ACY)"
                    else
                        NoTaxableAmount := "Base (LCY)";
                    if NoTaxablePrinted then
                        NoTaxableText := '';
                    NoTaxablePrinted := true;
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("VAT Reporting Date", VATEntry.GetFilter("VAT Reporting Date"));
                    if SortVATDate then
                        SetCurrentKey(Type, "VAT Reporting Date", "Document Type", "Document No.", "Source No.")
                    else
                        SetCurrentKey("No. Series", "VAT Reporting Date", "Document No.");
                    NoTaxableText := NoTaxableVATTxt;
                end;
            }

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                if PrintAmountsInAddCurrency then
                    HeaderText := StrSubstNo(Text1100002, GLSetup."Additional Reporting Currency")
                else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := StrSubstNo(Text1100002, GLSetup."LCY Code");
                end;

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
                    field(SortPostDate; SortVATDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Order by VAT date';
                        ToolTip = 'Specifies that the entries are sorted by VAT date.';
                    }
                    field(ShowAutoInvCred; ShowAutoInvCred)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Autoinvoices/Autocr. memo';
                        ToolTip = 'Specifies if the view includes invoices and credit memos that are created automatically.';
                    }
                    field(OnlyIncludeSIIDocumentsOption; OnlyIncludeSIIDocuments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Include SII Documents';
                        ToolTip = 'Specifies if only the documents to send to SII will be present in the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            ShowAutoInvCred := false;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        AuxVatEntry := VATEntry.GetFilters();
        MaxLines := 52;
    end;

    var
        Text1100000: Label 'VAT Registration No.: ';
        Text1100001: Label 'Specify the VAT registration number of your company in the Company information window.';
        Text1100002: Label 'All amounts are in %1.', Comment = '%1 - currency code';
        Text1100003: Label 'UNKNOWN';
        Text1100004: Label 'Invoice|Credit Memo';
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        CompanyInfo: Record "Company Information";
        VATBuffer: Record "Sales/Purch. Book VAT Buffer" temporary;
        VATBuffer2: Record "Sales/Purch. Book VAT Buffer";
        VATBuffer3: Record "Sales/Purch. Book VAT Buffer" temporary;
        VATBuffer4: Record "Sales/Purch. Book VAT Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        VendLedgEntry: Record "Vendor Ledger Entry";
        VatEntryTemporary: Record "VAT Entry" temporary;
        HeaderText: Text[250];
        CompanyAddr: array[7] of Text[100];
        LineNo: Decimal;
        Fin: Boolean;
        PrintAmountsInAddCurrency: Boolean;
        NoSeriesAux: Code[20];
        AutoDocNo: Code[20];
        AmountVatReverse: Decimal;
        NotBaseReverse: Decimal;
        NotAmountReverse: Decimal;
        NoSeriesAuxPrev: Code[20];
        AuxVatEntry: Text[250];
        SortVATDate: Boolean;
        SortPostDate: Boolean;
        Show: Boolean;
        i: Integer;
        PrevData: Date;
        Base2: Decimal;
        Amount2: Decimal;
        ShowAutoInvCred: Boolean;
        VarBase2: Decimal;
        VarAmount2: Decimal;
        VarNotBaseReverse: Decimal;
        VarNotAmountReverse: Decimal;
        AmountVatReverse3: Decimal;
        BaseImport: Decimal;
        TotalBaseImport: Decimal;
        MaxLines: Integer;
        Text1100005: Label 'Corrective Invoice';
        DocType: Text[30];
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Purchases_Invoice_BookCaptionLbl: Label 'Purchases Invoice Book';
        TotalCaptionLbl: Label 'Total';
        AmountCaptionLbl: Label 'Amount';
        EC_CaptionLbl: Label 'EC%';
        VAT_CaptionLbl: Label 'VAT%';
        BaseCaptionLbl: Label 'Base';
        VAT_RegistrationCaptionLbl: Label 'VAT Registration';
        NameCaptionLbl: Label 'Name';
        External_Document_No_CaptionLbl: Label 'External Document No.';
        VAT_DateCaptionLbl: Label 'VAT Date';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Document_DateCaptionLbl: Label 'Document Date';
        Document_No_CaptionLbl: Label 'Document No.';
        Epedition_DateCaptionLbl: Label 'Expedition Date';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control28Lbl: Label 'Continued';
        ContinuedCaption_Control48Lbl: Label 'Continued';
        ContinuedCaption_Control49Lbl: Label 'Continued';
        TotalCaption_Control77Lbl: Label 'Total';
        TotalCaption_Control78Lbl: Label 'Total';
        ContinuedCaption_Control18Lbl: Label 'Continued';
        ContinuedCaption_Control32Lbl: Label 'Continued';
        ContinuedCaption_Control130Lbl: Label 'Continued';
        ContinuedCaption_Control134Lbl: Label 'Continued';
        TotalCaption_Control54Lbl: Label 'Total';
        TotalCaption_Control127Lbl: Label 'Total';
        TotalCaption_Control26Lbl: Label 'Total';
        ContinuedCaption_Control103Lbl: Label 'Continued';
        No_SerieCaptionLbl: Label 'No. Series';
        TotalCaption_Control96Lbl: Label 'Total';
        No_SerieCaption_Control97Lbl: Label 'No. Series';
        ContinuedCaption_Control119Lbl: Label 'Continued';
        TotalCaption_Control21Lbl: Label 'Total';
        NonDeductibleVATCaptionLbl: Label 'Non-Ded. VAT%';
        NonDeductibleVATBaseCaptionLbl: Label 'Non-Ded. VAT Base';
        NonDeductibleVATAmtCaptionLbl: Label 'Non-Ded. VAT Amount';
        TempVATEntry: Record "VAT Entry" temporary;
        NoTaxableAmount: Decimal;
        NoTaxableVATTxt: Label 'No Taxable VAT';
        NoTaxableText: Text;
        NoTaxablePrinted: Boolean;
        OnlyIncludeSIIDocuments: Boolean;
}

