// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.Utilities;

report 10704 "Sales Invoice Book"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/SalesInvoiceBook.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Invoice Book';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("<Integer3>"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
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
            column(PrintAmountsInAddCurrency; PrintAmountsInAddCurrency)
            {
            }
            column(ShowAutoInvCred; ShowAutoInvCred)
            {
            }
            column(SortVATDate; SortVATDate)
            {
            }
            column(SortPostDate; SortVATDate)
            {
            }
            column(AuxVatEntry; AuxVatEntry)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(Integer3__Number; Number)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Sales_Invoice_BookCaption; Sales_Invoice_BookCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            column(VAT_DateCaption; VAT_DateCaptionLbl)
            {
            }
            column(External_Document_No_Caption; External_Document_No_CaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(VAT_RegistrationCaption; VAT_RegistrationCaptionLbl)
            {
            }
            column(BaseCaption; BaseCaptionLbl)
            {
            }
            column(VAT_Caption; VAT_CaptionLbl)
            {
            }
            column(EC_Caption; EC_CaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(Expedition_DateCaption; Expedition_DateCaptionLbl)
            {
            }
            dataitem(VATEntry; "VAT Entry")
            {
                DataItemTableView = sorting("No. Series", "VAT Reporting Date") where(Type = const(Sale));
                RequestFilterFields = "VAT Reporting Date", "Document Type", "Document No.";
                column(Base; -Base)
                {
                }
                column(Amount; -Amount)
                {
                }
                column(Base_Amount_; -(Base + Amount))
                {
                }
                column(Additional_Currency_Base_; -"Additional-Currency Base")
                {
                }
                column(Additional_Currency_Amount_; -"Additional-Currency Amount")
                {
                }
                column(Additional_Currency_Base___Additional_Currency_Amount__; -("Additional-Currency Base" + "Additional-Currency Amount"))
                {
                }
                column(Base_Base2; -Base + Base2)
                {
                }
                column(Amount_Amount2; -Amount + Amount2)
                {
                }
                column(Base_Base2____Amount_Amount2_; (-Base + Base2) + (-Amount + Amount2))
                {
                }
                column(Additional_Currency_Base__Base2_____Additional_Currency_Amount__Amount2_; (-"Additional-Currency Base" + Base2) + (-"Additional-Currency Amount" + Amount2))
                {
                }
                column(Additional_Currency_Base__Base2; -"Additional-Currency Base" + Base2)
                {
                }
                column(Additional_Currency_Amount__Amount2; -"Additional-Currency Amount" + Amount2)
                {
                }
                column(VATEntry__No__Series_; "No. Series")
                {
                }
                column(VATEntry__No__Series__Control49; "No. Series")
                {
                }
                column(Additional_Currency_Base__Control74; -"Additional-Currency Base")
                {
                }
                column(Additional_Currency_Amount__Control80; -"Additional-Currency Amount")
                {
                }
                column(Additional_Currency_Base___Additional_Currency_Amount___Control81; -("Additional-Currency Base" + "Additional-Currency Amount"))
                {
                }
                column(Base_Control73; -Base)
                {
                }
                column(Amount_Control75; -Amount)
                {
                }
                column(Base_Amount__Control76; -(Base + Amount))
                {
                }
                column(VATEntry__No__Series__Control79; "No. Series")
                {
                }
                column(Base_Base2_Control50; -Base + Base2)
                {
                }
                column(Amount_Amount2_Control54; -Amount + Amount2)
                {
                }
                column(Base_Base2____Amount_Amount2__Control104; (-Base + Base2) + (-Amount + Amount2))
                {
                }
                column(Additional_Currency_Base__Base2_____Additional_Currency_Amount__Amount2__Control135; (-"Additional-Currency Base" + Base2) + (-"Additional-Currency Amount" + Amount2))
                {
                }
                column(Additional_Currency_Base__Base2_Control137; -"Additional-Currency Base" + Base2)
                {
                }
                column(Additional_Currency_Amount__Amount2_Control138; -"Additional-Currency Amount" + Amount2)
                {
                }
                column(Base_Control61; -Base)
                {
                }
                column(Amount_Control62; -Amount)
                {
                }
                column(Base_Amount__Control63; -(Base + Amount))
                {
                }
                column(Additional_Currency_Base__Control33; -"Additional-Currency Base")
                {
                }
                column(Additional_Currency_Amount__Control34; -"Additional-Currency Amount")
                {
                }
                column(Additional_Currency_Base___Additional_Currency_Amount___Control35; -("Additional-Currency Base" + "Additional-Currency Amount"))
                {
                }
                column(Base_Base2_Control55; -Base + Base2)
                {
                }
                column(Amount_Amount2_Control56; -Amount + Amount2)
                {
                }
                column(Base_Base2____Amount_Amount2__Control57; (-Base + Base2) + (-Amount + Amount2))
                {
                }
                column(Additional_Currency_Base__Base2_Control106; -"Additional-Currency Base" + Base2)
                {
                }
                column(Additional_Currency_Amount__Amount2_Control118; -"Additional-Currency Amount" + Amount2)
                {
                }
                column(Additional_Currency_Base__Base2_____Additional_Currency_Amount__Amount2__Control119; (-"Additional-Currency Base" + Base2) + (-"Additional-Currency Amount" + Amount2))
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
                column(ContinuedCaption_Control128; ContinuedCaption_Control128Lbl)
                {
                }
                column(ContinuedCaption_Control136; ContinuedCaption_Control136Lbl)
                {
                }
                column(VATEntry__No__Series_Caption; FieldCaption("No. Series"))
                {
                }
                column(VATEntry__No__Series__Control49Caption; FieldCaption("No. Series"))
                {
                }
                column(TotalCaption_Control72; TotalCaption_Control72Lbl)
                {
                }
                column(TotalCaption_Control77; TotalCaption_Control77Lbl)
                {
                }
                column(VATEntry__No__Series__Control79Caption; FieldCaption("No. Series"))
                {
                }
                column(ContinuedCaption_Control105; ContinuedCaption_Control105Lbl)
                {
                }
                column(ContinuedCaption_Control120; ContinuedCaption_Control120Lbl)
                {
                }
                column(ContinuedCaption_Control60; ContinuedCaption_Control60Lbl)
                {
                }
                column(ContinuedCaption_Control32; ContinuedCaption_Control32Lbl)
                {
                }
                column(TotalCaption_Control48; TotalCaption_Control48Lbl)
                {
                }
                column(TotalCaption_Control70; TotalCaption_Control70Lbl)
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
                                        VATBuffer3.Modify();
                                    end else begin
                                        VATBuffer3.Base := Base;
                                        VATBuffer3.Amount := Amount;
                                        VATBuffer3.Insert();
                                    end
                                else
                                    if VATBuffer3.Find() then begin
                                        VATBuffer3.Base := VATBuffer3.Base + "Additional-Currency Base";
                                        VATBuffer3.Amount := VATBuffer3.Amount + "Additional-Currency Amount";
                                        VATBuffer3.Modify();
                                    end else begin
                                        VATBuffer3.Base := "Additional-Currency Base";
                                        VATBuffer3.Amount := "Additional-Currency Amount";
                                        VATBuffer3.Insert();
                                    end
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
                                        VendLedgEntry.SetRange("Document Type", "Document Type"::Invoice);
                                        VendLedgEntry.SetRange("Document No.", VATEntry6."Document No.");
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
                        column(VATBuffer4__EC___; VATBuffer4."EC %")
                        {
                        }
                        column(VATBuffer4__VAT___; VATBuffer4."VAT %")
                        {
                        }
                        column(VATBuffer4_Base; VATBuffer4.Base)
                        {
                        }
                        column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                        {
                        }
                        column(CompanyInfo_Name; CompanyInfo.Name)
                        {
                        }
                        column(VATEntry6__Document_No__; VATEntry6."Document No.")
                        {
                        }
                        column(VATEntry6__Posting_Date_; Format(VATEntry6."Posting Date"))
                        {
                        }
                        column(VATEntry6__VAT_Date_; Format(VATEntry6."VAT Reporting Date"))
                        {
                        }
                        column(AutoDocNo; AutoDocNo)
                        {
                        }
                        column(DocType; DocType)
                        {
                        }
                        column(FORMAT_VATEntry6__Document_Date__; Format(VATEntry6."Document Date"))
                        {
                        }
                        column(VATBuffer4_Base_VATBuffer4_Amount_Control43; VATBuffer4.Base + VATBuffer4.Amount)
                        {
                        }
                        column(VATBuffer4_Amount_Control44; VATBuffer4.Amount)
                        {
                        }
                        column(VATBuffer4__EC____Control45; VATBuffer4."EC %")
                        {
                        }
                        column(VATBuffer4__VAT____Control46; VATBuffer4."VAT %")
                        {
                        }
                        column(VATBuffer4_Base_Control47; VATBuffer4.Base)
                        {
                        }
                        column(Integer4__Number; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if not SortVATDate then begin
                                if VATBuffer4.Amount = 0 then begin
                                    VATBuffer4."VAT %" := 0;
                                    VATBuffer4."EC %" := 0;
                                end;
                                Base2 := Base2 + VATBuffer4.Base;
                                Amount2 := Amount2 + VATBuffer4.Amount;
                            end;

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
                    DataItemLink = Type = field(Type), "VAT Reporting Date" = field("VAT Reporting Date"), "Document Type" = field("Document Type"), "Document No." = field("Document No.");
                    DataItemTableView = sorting("No. Series", "VAT Reporting Date");

                    trigger OnAfterGetRecord()
                    begin
                        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then begin
                            VATBuffer."VAT %" := 0;
                            VATBuffer."EC %" := 0;
                        end else begin
                            VATBuffer."VAT %" := "VAT %";
                            VATBuffer."EC %" := "EC %";
                        end;
                        if not PrintAmountsInAddCurrency then begin
                            if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                                Base := 0;
                            if VATBuffer.Find() then begin
                                VATBuffer.Base := VATBuffer.Base - Base;
                                VATBuffer.Amount := VATBuffer.Amount - Amount;
                                VATBuffer.Modify();
                            end else begin
                                VATBuffer.Base := -Base;
                                VATBuffer.Amount := -Amount;
                                VATBuffer.Insert();
                            end;
                        end else begin
                            if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                                "Additional-Currency Base" := 0;
                            if VATBuffer.Find() then begin
                                VATBuffer.Base := VATBuffer.Base - "Additional-Currency Base";
                                VATBuffer.Amount := VATBuffer.Amount - "Additional-Currency Amount";
                                VATBuffer.Modify();
                            end else begin
                                VATBuffer.Base := -"Additional-Currency Base";
                                VATBuffer.Amount := -"Additional-Currency Amount";
                                VATBuffer.Insert();
                            end;
                        end;
                        TempVATEntry := VATEntry2;
                        if not TempVATEntry.Find() then
                            TempVATEntry.Insert();
                    end;

                    trigger OnPreDataItem()
                    var
                        ShouldExit: Boolean;
                    begin
                        if SortVATDate then
                            SetCurrentKey(Type, "VAT Reporting Date", "Document Type", "Document No.", "Bill-to/Pay-to No.")
                        else
                            SetCurrentKey("No. Series", "VAT Reporting Date");

                        SetRange("No. Series", VATEntry."No. Series");
                        Clear(SalesCrMemoHeader);
                        Clear(SalesInvHeader);
                        Clear(Customer);

                        if not PrintAmountsInAddCurrency then
                            GLSetup.Get()
                        else begin
                            GLSetup.Get();
                            Currency.Get(GLSetup."Additional Reporting Currency");
                        end;

                        case VATEntry."Document Type" of
                            VATEntry."Document Type"::"Credit Memo":
                                begin
                                    if SalesCrMemoHeader.Get(VATEntry."Document No.") then begin
                                        Customer.Name := SalesCrMemoHeader."Bill-to Name";
                                        Customer."VAT Registration No." := SalesCrMemoHeader."VAT Registration No.";
                                        exit;
                                    end;
                                    ShouldExit := false;
                                    OnAfterUpdateCustomerData(VATEntry, Customer, ShouldExit);
                                    if ShouldExit then
                                        exit;
                                end;
                            VATEntry."Document Type"::Invoice:
                                begin
                                    if SalesInvHeader.Get(VATEntry."Document No.") then begin
                                        Customer.Name := SalesInvHeader."Bill-to Name";
                                        Customer."VAT Registration No." := SalesInvHeader."VAT Registration No.";
                                        exit;
                                    end;
                                    ShouldExit := false;
                                    OnAfterUpdateCustomerData(VATEntry, Customer, ShouldExit);
                                    if ShouldExit then
                                        exit;
                                end;
                        end;

                        if not Customer.Get(VATEntry."Bill-to/Pay-to No.") then
                            Customer.Name := Text1100003;
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
                    column(VATBuffer2_Amount; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2__VAT___; VATBuffer2."VAT %")
                    {
                    }
                    column(VATBuffer2__EC___; VATBuffer2."EC %")
                    {
                    }
                    column(VATEntry2__Posting_Date_; Format(VATEntry2."Posting Date"))
                    {
                    }
                    column(VATEntry2__VAT_Date_; Format(VATEntry2."VAT Reporting Date"))
                    {
                    }
                    column(Customer_Name; Customer.Name)
                    {
                    }
                    column(Customer__VAT_Registration_No__; Customer."VAT Registration No.")
                    {
                    }
                    column(DocType_Control25; DocType)
                    {
                    }
                    column(VATBuffer2_Base_VATBuffer2_Amount; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(FORMAT_VATEntry2__Document_Date__; Format(VATEntry2."Document Date"))
                    {
                    }
                    column(VATBuffer2_Base_Control13; VATBuffer2.Base)
                    {
                    }
                    column(VATBuffer2__VAT____Control15; VATBuffer2."VAT %")
                    {
                    }
                    column(VATBuffer2__EC____Control16; VATBuffer2."EC %")
                    {
                    }
                    column(VATBuffer2_Amount_Control14; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_VATBuffer2_Amount_Control12; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_Control17; VATBuffer2.Base)
                    {
                    }
                    column(VATBuffer2_Amount_Control18; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_VATBuffer2_Amount_Control23; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(Integer_Number; Number)
                    {
                    }
                    column(TotalCaption_Control26; TotalCaption_Control26Lbl)
                    {
                    }
                    column(VATEntry2_External_Document_No__; VATEntry2."External Document No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Fin then
                            CurrReport.Break();
                        VATBuffer2 := VATBuffer;
                        Fin := VATBuffer.Next() = 0;
                        LineNo := LineNo + 1;
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
            dataitem(VATEntry4; "VAT Entry")
            {
                DataItemTableView = sorting("Document Type", "No. Series", "VAT Reporting Date") where(Type = const(Purchase));
                column(VarNotBaseReverse; VarNotBaseReverse)
                {
                }
                column(VarNotAmountReverse; VarNotAmountReverse)
                {
                }
                column(VarNotBaseReverse_VarNotAmountReverse; VarNotBaseReverse + VarNotAmountReverse)
                {
                }
                column(No_SeriesAux_; NoSeriesAux)
                {
                }
                column(No_SeriesAux__Control101; NoSeriesAux)
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
                column(VarNotBaseReverse_Control108; VarNotBaseReverse)
                {
                }
                column(VarNotAmountReverse_Control110; VarNotAmountReverse)
                {
                }
                column(VarNotBaseReverse_VarNotAmountReverse_Control112; VarNotBaseReverse + VarNotAmountReverse)
                {
                }
                column(VATEntry4_Entry_No_; "Entry No.")
                {
                }
                column(VATEntry4_Document_Type; "Document Type")
                {
                }
                column(VATEntry4_Type; Type)
                {
                }
                column(VATEntry4_Posting_Date; "Posting Date")
                {
                }
                column(VATEntry4_VAT_Date; "VAT Reporting Date")
                {
                }
                column(VATEntry4_Document_No_; "Document No.")
                {
                }
                column(ContinuedCaption_Control129; ContinuedCaption_Control129Lbl)
                {
                }
                column(No_SerieCaption; No_SerieCaptionLbl)
                {
                }
                column(TotalCaption_Control99; TotalCaption_Control99Lbl)
                {
                }
                column(No_SerieCaption_Control100; No_SerieCaption_Control100Lbl)
                {
                }
                column(ContinuedCaption_Control117; ContinuedCaption_Control117Lbl)
                {
                }
                dataitem(VATEntry5; "VAT Entry")
                {
                    DataItemLink = Type = field(Type), "VAT Reporting Date" = field("VAT Reporting Date"), "Document Type" = field("Document Type"), "Document No." = field("Document No.");
                    DataItemTableView = sorting("No. Series", "VAT Reporting Date");

                    trigger OnAfterGetRecord()
                    begin
                        VATBuffer."VAT %" := "VAT %";
                        VATBuffer."EC %" := "EC %";

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
                        VATEntry4 := VATEntry5;
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
                        case VATEntry4."Document Type" of
                            "Document Type"::"Credit Memo":
                                if PurchCrMemoHeader.Get(VATEntry4."Document No.") then begin
                                    Vendor.Name := PurchCrMemoHeader."Pay-to Name";
                                    Vendor."VAT Registration No." := PurchCrMemoHeader."VAT Registration No.";
                                    VendLedgEntry.SetRange("Document No.", VATEntry4."Document No.");
                                    VendLedgEntry.SetRange("Document Type", "Document Type"::"Credit Memo");
                                    if VendLedgEntry.FindFirst() then
                                        AutoDocNo := VendLedgEntry."Autodocument No.";
                                    exit;
                                end;
                            "Document Type"::Invoice:
                                if PurchInvHeader.Get(VATEntry4."Document No.") then begin
                                    Vendor.Name := PurchInvHeader."Pay-to Name";
                                    Vendor."VAT Registration No." := PurchInvHeader."VAT Registration No.";
                                    VendLedgEntry.SetRange("Document No.", VATEntry4."Document No.");
                                    VendLedgEntry.SetRange("Document Type", "Document Type"::Invoice);
                                    if VendLedgEntry.FindFirst() then
                                        AutoDocNo := VendLedgEntry."Autodocument No.";
                                    exit;
                                end;
                        end;

                        if not Vendor.Get(VATEntry4."Bill-to/Pay-to No.") then
                            Vendor.Name := Text1100003;
                        VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
                        VendLedgEntry.SetRange("Document No.", VATEntry4."Document No.");
                        VendLedgEntry.SetFilter("Document Type", Text1100004);
                        if VendLedgEntry.FindFirst() then;
                    end;
                }
                dataitem("<Integer2>"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VATBuffer2_Base_VATBuffer2_Amount_Control82; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Amount_Control83; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2__EC____Control84; VATBuffer2."EC %")
                    {
                    }
                    column(VATBuffer2__VAT____Control85; VATBuffer2."VAT %")
                    {
                    }
                    column(VATBuffer2_Base_Control86; VATBuffer2.Base)
                    {
                    }
                    column(CompanyInfo__VAT_Registration_No___Control87; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfo_Name_Control88; CompanyInfo.Name)
                    {
                    }
                    column(VATEntry4__Posting_Date_; Format(VATEntry4."Posting Date"))
                    {
                    }
                    column(VATEntry4__VAT_Date_; Format(VATEntry4."VAT Reporting Date"))
                    {
                    }
                    column(AutoDocNo_Control91; AutoDocNo)
                    {
                    }
                    column(VATEntry4__Document_Type_; VATEntry4."Document Type")
                    {
                    }
                    column(VATEntry4__Document_No__; VATEntry4."Document No.")
                    {
                    }
                    column(FORMAT_VATEntry4__Document_Date__; Format(VATEntry4."Document Date"))
                    {
                    }
                    column(VATBuffer2_Base_Control93; VATBuffer2.Base)
                    {
                    }
                    column(VATBuffer2__VAT____Control94; VATBuffer2."VAT %")
                    {
                    }
                    column(VATBuffer2__EC____Control95; VATBuffer2."EC %")
                    {
                    }
                    column(VATBuffer2_Amount_Control96; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_VATBuffer2_Amount_Control97; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_Control114; VATBuffer2.Base)
                    {
                    }
                    column(VATBuffer2_Amount_Control115; VATBuffer2.Amount)
                    {
                    }
                    column(VATBuffer2_Base_VATBuffer2_Amount_Control116; VATBuffer2.Base + VATBuffer2.Amount)
                    {
                    }
                    column(Integer2__Number; Number)
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
                        VarNotBaseReverse := VarNotBaseReverse + VATBuffer2.Base;
                        VarNotAmountReverse := VarNotAmountReverse + VATBuffer2.Amount;
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
                    if not ShowAutoInvCred then
                        CurrReport.Break();
                    SetRange("Generated Autodocument", true);
                    if Find('-') then;
                    SetFilter("VAT Reporting Date", VATEntry.GetFilter("VAT Reporting Date"));
                    SetFilter("Document No.", VATEntry.GetFilter("Document No."));
                    SetFilter("Document Type", VATEntry.GetFilter("Document Type"));
                end;
            }
            dataitem("No Taxable Entry"; "No Taxable Entry")
            {
                DataItemTableView = sorting("Entry No.") where(Type = const(Sale), Reversed = const(false), "Not In 347" = const(false));
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
                column(SourceName_NoTaxableEntry; Customer.Name)
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
                column(DocumentDate_NoTaxableEntry; "Document Date")
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
                    if not Customer.Get("Source No.") then
                        Customer.Name := Text1100003;
                    if PrintAmountsInAddCurrency then
                        NoTaxableAmount := -"Base (ACY)"
                    else
                        NoTaxableAmount := -"Base (LCY)";
                    if NoTaxablePrinted then
                        NoTaxableText := '';
                    NoTaxablePrinted := true;
                end;

                trigger OnPreDataItem()
                begin
                    if SortVATDate then
                        SetCurrentKey(Type, "VAT Reporting Date", "Document Type", "Document No.", "Source No.")
                    else
                        SetCurrentKey("No. Series", "VAT Reporting Date", "Document No.");
                    SetFilter("VAT Reporting Date", VATEntry.GetFilter("VAT Reporting Date"));
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
                    field(ShowAutoInvoicesAutoCrMemo; ShowAutoInvCred)
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
    end;

    var
        Text1100000: Label 'VAT Registration No.: ';
        Text1100001: Label 'Specify the VAT registration number of your company in the Company information window.';
        Text1100002: Label 'All amounts are in %1.', Comment = '%1 - currency code';
        Text1100003: Label 'UNKNOWN';
        Text1100004: Label 'Invoice|Credit Memo';
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        VATBuffer: Record "Sales/Purch. Book VAT Buffer" temporary;
        VATBuffer2: Record "Sales/Purch. Book VAT Buffer";
        VATBuffer3: Record "Sales/Purch. Book VAT Buffer" temporary;
        VATBuffer4: Record "Sales/Purch. Book VAT Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        VatEntryTemporary: Record "VAT Entry" temporary;
        HeaderText: Text[250];
        CompanyAddr: array[7] of Text[100];
        LineNo: Decimal;
        Fin: Boolean;
        PrintAmountsInAddCurrency: Boolean;
        NoSeriesAux: Code[20];
        AutoDocNo: Code[20];
        NotBaseReverse: Decimal;
        NotAmountReverse: Decimal;
        NoSeriesAuxPrev: Code[20];
        AuxVatEntry: Text[250];
        PrevData: Date;
        SortVATDate: Boolean;
        Show: Boolean;
        i: Integer;
        ShowAutoInvCred: Boolean;
        Base2: Decimal;
        Amount2: Decimal;
        VarBase2: Decimal;
        VarAmount2: Decimal;
        VarNotBaseReverse: Decimal;
        VarNotAmountReverse: Decimal;
        DocType: Text[30];
        Text1100005: Label 'Corrective Invoice';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Sales_Invoice_BookCaptionLbl: Label 'Sales Invoice Book';
        Document_No_CaptionLbl: Label 'Document No.';
        Posting_DateCaptionLbl: Label 'Posting Date';
        VAT_DateCaptionLbl: Label 'VAT Date';
        External_Document_No_CaptionLbl: Label 'External Document No.';
        NameCaptionLbl: Label 'Name';
        VAT_RegistrationCaptionLbl: Label 'VAT Registration';
        BaseCaptionLbl: Label 'Base';
        VAT_CaptionLbl: Label 'VAT%';
        EC_CaptionLbl: Label 'EC%';
        AmountCaptionLbl: Label 'Amount';
        TotalCaptionLbl: Label 'Total';
        Expedition_DateCaptionLbl: Label 'Expedition Date';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control28Lbl: Label 'Continued';
        ContinuedCaption_Control128Lbl: Label 'Continued';
        ContinuedCaption_Control136Lbl: Label 'Continued';
        TotalCaption_Control72Lbl: Label 'Total';
        TotalCaption_Control77Lbl: Label 'Total';
        ContinuedCaption_Control105Lbl: Label 'Continued';
        ContinuedCaption_Control120Lbl: Label 'Continued';
        ContinuedCaption_Control60Lbl: Label 'Continued';
        ContinuedCaption_Control32Lbl: Label 'Continued';
        TotalCaption_Control48Lbl: Label 'Total';
        TotalCaption_Control70Lbl: Label 'Total';
        TotalCaption_Control26Lbl: Label 'Total';
        ContinuedCaption_Control129Lbl: Label 'Continued';
        No_SerieCaptionLbl: Label 'No. Series';
        TotalCaption_Control99Lbl: Label 'Total';
        No_SerieCaption_Control100Lbl: Label 'No. Series';
        ContinuedCaption_Control117Lbl: Label 'Continued';
        TempVATEntry: Record "VAT Entry" temporary;
        NoTaxableAmount: Decimal;
        NoTaxableVATTxt: Label 'No Taxable VAT';
        NoTaxableText: Text;
        NoTaxablePrinted: Boolean;
        OnlyIncludeSIIDocuments: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCustomerData(VATEntry: Record "VAT Entry"; var Customer: Record Customer; var ShouldExit: Boolean)
    begin
    end;
}

