// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.CRM.Contact;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Utilities;

report 12120 "VAT Register - Print"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/VATRegisterPrint.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Fiscal Register - Print';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(PrintCompinfo; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(CompanyInformation_1_; CompanyInformation[1])
            {
            }
            column(CompanyInformation_2_; CompanyInformation[2])
            {
            }
            column(CompanyInformation_3_; CompanyInformation[3])
            {
            }
            column(CompanyInformation_7_; CompanyInformation[7])
            {
            }
            column(CompanyInformation_4_; CompanyInformation[4])
            {
            }
            column(CompanyInformation_6_; CompanyInformation[6])
            {
            }
            column(CompanyInformation_5_; CompanyInformation[5])
            {
            }
            column(PageNoPrefix; StrSubstNo(Text1038, Format(Date2DMY(StartingDate, 3))))
            {
            }
            column(VATRegisterLastPrintedPageNo; VATRegisterLastPrintedPageNo)
            {
            }
            column(PrintCompanyInformations; PrintCompanyInformations)
            {
            }
            column(PrintCompinfo_Number; Number)
            {
            }
            column(CompanyInfo_1_5; CompanyInformation[1] + '    ' + CompanyInformation[2] + '    ' + CompanyInformation[3] + '    ' + Text1046 + CompanyInformation[5])
            {
            }
            column(Fiscal_Code_Caption; Fiscal_Code_CaptionLbl)
            {
            }
            column(Register_Company_No_Caption; Register_Company_No_CaptionLbl)
            {
            }
            column(CompanyInformation_5_Caption; CompanyInformation_5_CaptionLbl)
            {
            }
            column(StartingDate; Format(StartingDate))
            {
            }
            column(EndingDate; Format(EndingDate))
            {
            }
            column(IsSales; IsSales)
            {
            }
            column(StartingDateCaption; StartingDateCaptionLbl)
            {
            }
            column(StartingDate_Control1130062Caption; StartingDate_Control1130062CaptionLbl)
            {
            }
            column(Purchase_VAT_RegisterCaption; Purchase_VAT_RegisterCaptionLbl)
            {
            }
            column(Sales_VAT_RegisterCaption; Sales_VAT_RegisterCaptionLbl)
            {
            }

            trigger OnPostDataItem()
            begin
                if not PrintCompanyInformations then
                    CurrReport.NewPage();
            end;

            trigger OnPreDataItem()
            begin
                if PrintCompanyInformations then
                    for i := 1 to 6 do
                        if CompanyInformation[i] = '' then
                            Error(Text1049);
            end;
        }
        dataitem("VAT Register"; "VAT Register")
        {
            DataItemTableView = sorting(Code) order(ascending);
            PrintOnlyIfDetail = true;
            column(VAT_Register_Code; Code)
            {
            }
            column(PrintingType; PrintingType)
            {
            }
            column(PrintLegend; PrintLegend)
            {
            }
            column(ShowFirstSection; ShowFirstSection)
            {
            }
            column(VAT_Register_Type; Type)
            {
            }
            column(VATBookEntry__No__Series_; VATBookEntry."No. Series")
            {
            }
            column(RegisterTypeSales; RegisterTypeSales)
            {
            }
            column(RegisterTypePurchase; RegisterTypePurchase)
            {
            }
            column(DocumentTotalCaption; DocumentTotalCaptionLbl)
            {
            }
            column(PageNoPrefix1; StrSubstNo(Text1038, Format(Date2DMY(StartingDate, 3))))
            {
            }
            column(VATRegisterLastPrintedPageNo1; VATRegisterLastPrintedPageNo)
            {
            }
            column(VATRegCaption; VATRegCaptionLbl)
            {
            }
            column(IntraCCaption; IntraCCaptionLbl)
            {
            }
            column(Unrealized_Amount_Caption; Unrealized_Amount_CaptionLbl)
            {
            }
            column(Unrealized_Base_Caption; Unrealized_Base_CaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(BaseCaption; BaseCaptionLbl)
            {
            }
            column(DescrVATIdentifierCaption; DescrVATIdentifierCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(VAT_Book_Entry__Document_Date_Caption; VAT_Book_Entry__Document_Date_CaptionLbl)
            {
            }
            column(VAT_Book_Entry__Posting_Date_Caption; VAT_Book_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(VATReg_Control1130066Caption; VATReg_Control1130066CaptionLbl)
            {
            }
            column(IntraC_Control1130065Caption; IntraC_Control1130065CaptionLbl)
            {
            }
            column(DocumentTotal_Control1130069Caption; DocumentTotal_Control1130069CaptionLbl)
            {
            }
            column(DescrVATIdentifier_Control1130074Caption; DescrVATIdentifier_Control1130074CaptionLbl)
            {
            }
            column(Name_Control1130075Caption; Name_Control1130075CaptionLbl)
            {
            }
            column(VAT_Book_Entry__Sell_to_Buy_from_No___Control1130076Caption; VAT_Book_Entry__Sell_to_Buy_from_No___Control1130076CaptionLbl)
            {
            }
            column(VAT_Book_Entry__Document_No___Control1130077Caption; VATEntry__Document_No__CaptionLbl)
            {
            }
            column(DocTypeCaption; DocTypeCaptionLbl)
            {
            }
            column(VAT_Book_Entry__External_Document_No__Caption; VAT_Book_Entry__External_Document_No__CaptionLbl)
            {
            }
            column(VAT_Book_Entry__Document_Date__Control1130080Caption; VAT_Book_Entry__Document_Date__Control1130080CaptionLbl)
            {
            }
            column(VAT_Book_Entry__Posting_Date__Control1130081Caption; VAT_Book_Entry__Posting_Date__Control1130081CaptionLbl)
            {
            }
            dataitem("No. Series"; "No. Series")
            {
                DataItemLink = "VAT Register" = field(Code);
                DataItemLinkReference = "VAT Register";
                DataItemTableView = sorting("VAT Reg. Print Priority") order(ascending);
                PrintOnlyIfDetail = true;
                column(No__Series_Code; Code)
                {
                }
                column(No__Series_VAT_Register; "VAT Register")
                {
                }
                dataitem("VAT Book Entry"; "VAT Book Entry")
                {
                    CalcFields = "Document Type", Base, Amount, "VAT Calculation Type", "Sell-to/Buy-from No.", "External Document No.", "No. Series", "Nondeductible Amount", "Document Date", "VAT Difference", "Nondeductible Base", "Unrealized Base", "Unrealized Amount";
                    DataItemLink = "No. Series" = field(Code);
                    DataItemLinkReference = "No. Series";
                    DataItemTableView = sorting("Document No.", "Posting Date") order(ascending) where(Type = filter(<> Settlement), "Unrealized VAT" = filter(false));
                    column(IntraC; IntraC)
                    {
                    }
                    column(VATReg; VATReg)
                    {
                    }
                    column(DocumentTotal; DocumentTotal)
                    {
                        AutoFormatType = 1;
                    }
                    column(Unrealized_Amount_; -"Unrealized Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(Unrealized_Base_; -"Unrealized Base")
                    {
                        AutoFormatType = 1;
                    }
                    column(Amount; -Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(Base; -Base)
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Book_Entry__VAT___; "VAT %")
                    {
                    }
                    column(DescrVATIdentifier; DescrVATIdentifier)
                    {
                    }
                    column(Name; Name)
                    {
                    }
                    column(VAT_Book_Entry__Sell_to_Buy_from_No__; "Sell-to/Buy-from No.")
                    {
                    }
                    column(VAT_Book_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(VAT_Book_Entry__Document_Date_; Format("Document Date"))
                    {
                    }
                    column(VAT_Book_Entry__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(VATBookEntry__Entry_No__; VATBookEntry."Entry No.")
                    {
                    }
                    column(VAT_Book_Entry__Nondeductible_Amount_; "Nondeductible Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Book_Entry__Nondeductible_Base_; "Nondeductible Base")
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Book_Entry_Amount; Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Book_Entry_Base; Base)
                    {
                        AutoFormatType = 1;
                    }
                    column(VAT_Book_Entry__Deductible___; "Deductible %")
                    {
                    }
                    column(DocType; DocType)
                    {
                    }
                    column(VAT_Book_Entry__External_Document_No__; "External Document No.")
                    {
                    }
                    column(VAT_Book_Entry__Unrealized_Amount_; "Unrealized Amount")
                    {
                    }
                    column(VAT_Book_Entry__Unrealized_Base_; "Unrealized Base")
                    {
                    }
                    column(VAT_Book_Entry_Base_Control1130094; Base)
                    {
                        AutoFormatType = 1;
                    }
                    column(LedgAmount; -LedgAmount)
                    {
                        AutoFormatExpression = LedgCurrCode;
                        AutoFormatType = 1;
                        DecimalPlaces = 0 : 2;
                    }
                    column(LedgCurrCode; LedgCurrCode)
                    {
                    }
                    column(LedgAmount_Control1130104; LedgAmount)
                    {
                        AutoFormatExpression = LedgCurrCode;
                        AutoFormatType = 1;
                        DecimalPlaces = 0 : 2;
                    }
                    column(VAT_Book_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(VAT_Book_Entry_No__Series; "No. Series")
                    {
                    }
                    column(LedgCurrCodeCaption; LedgCurrCodeCaptionLbl)
                    {
                    }
                    column(LedgAmountCaption; LedgAmountCaptionLbl)
                    {
                    }
                    column(LedgCurrCode_Control1130102Caption; LedgCurrCode_Control1130102CaptionLbl)
                    {
                    }
                    column(LedgAmount_Control1130104Caption; LedgAmount_Control1130104CaptionLbl)
                    {
                    }
                    column(VAT_Book_Entry__Document_No__Caption; FieldCaption("Document No."))
                    {
                    }
                    column(VAT_Book_Entry__VAT___Caption; FieldCaption("VAT %"))
                    {
                    }
                    column(VAT_Book_Entry__Sell_to_Buy_from_No__Caption; FieldCaption("Sell-to/Buy-from No."))
                    {
                    }
                    column(VAT_Book_Entry__Nondeductible_Amount_Caption; FieldCaption("Nondeductible Amount"))
                    {
                    }
                    column(VAT_Book_Entry__Nondeductible_Base_Caption; FieldCaption("Nondeductible Base"))
                    {
                    }
                    column(VAT_Book_Entry_AmountCaption; FieldCaption(Amount))
                    {
                    }
                    column(VAT_Book_Entry_BaseCaption; FieldCaption(Base))
                    {
                    }
                    column(VAT_Book_Entry__Deductible___Caption; FieldCaption("Deductible %"))
                    {
                    }
                    column(VAT_Book_Entry__Unrealized_Amount_Caption; FieldCaption("Unrealized Amount"))
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Name := '';
                        VATReg := '';

                        if "VAT Register".Type = "VAT Register".Type::Purchase then
                            DocumentTotal := DocumentTotalCalculation("Transaction No.", "Document No.", 0)
                        else
                            DocumentTotal := -DocumentTotalCalculation("Transaction No.", "Document No.", 0);

                        if "Document Type" = "Document Type"::Invoice then
                            DocType := 'Fatt.'
                        else
                            if "Document Type" = "Document Type"::"Credit Memo" then
                                DocType := 'N.Cr.'
                            else
                                DocType := '';

                        if ("VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT") and
                           IsForeignCV("VAT Book Entry")
                        then begin
                            PrintLegend := true;
                            IntraC := 'I.O.';
                        end else
                            IntraC := '';

                        VATBookEntryTemp.Reset();
                        VATBookEntryTemp.SetRange("VAT Identifier", "VAT Identifier");
                        VATBookEntryTemp.SetRange("VAT %", "VAT %");
                        VATBookEntryTemp.SetRange("Deductible %", "Deductible %");

                        if VATBookEntryTemp.Find('-') then begin
                            VATBookEntryTemp.Base := VATBookEntryTemp.Base + Base;
                            VATBookEntryTemp.Amount := VATBookEntryTemp.Amount + Amount;
                            VATBookEntryTemp."Nondeductible Base" := VATBookEntryTemp."Nondeductible Base" + "Nondeductible Base";
                            VATBookEntryTemp."Nondeductible Amount" := VATBookEntryTemp."Nondeductible Amount" + "Nondeductible Amount";
                            VATBookEntryTemp."Unrealized Base" := VATBookEntryTemp."Unrealized Base" + "Unrealized Base";
                            VATBookEntryTemp."Unrealized Amount" := VATBookEntryTemp."Unrealized Amount" + "Unrealized Amount";
                            VATBookEntryTemp.Modify();
                        end else begin
                            VATBookEntryTemp.Init();
                            VATBookEntryTemp."VAT Identifier" := "VAT Identifier";
                            VATBookEntryTemp."VAT %" := "VAT %";
                            VATBookEntryTemp."Deductible %" := "Deductible %";
                            VATBookEntryTemp.Base := Base;
                            VATBookEntryTemp.Amount := Amount;
                            VATBookEntryTemp."Nondeductible Base" := "Nondeductible Base";
                            VATBookEntryTemp."Nondeductible Amount" := "Nondeductible Amount";
                            VATBookEntryTemp."Unrealized Base" := "Unrealized Base";
                            VATBookEntryTemp."Unrealized Amount" := "Unrealized Amount";
                            VATBookEntryTemp."Entry No." := "Entry No.";
                            VATBookEntryTemp.Insert();
                            VATLines := VATLines + 1;
                        end;

                        VATIdentifier.Get("VAT Identifier");
                        DescrVATIdentifier := VATIdentifier.Code;

                        if (PrintingType = PrintingType::Final) and not PreviewRegister then begin
                            VATBookEntry := "VAT Book Entry";
                            UpdateBuffer();
                            if not HasBeenMarked then
                                HasBeenMarked := true;
                            VATBookEntry."Printing Date" := Today;
                            VATBookEntry.Modify();
                        end;

                        if OldDocumentNo <> "Document No." then
                            ShowFirstSection := true
                        else
                            ShowFirstSection := false;

                        LedgAmount := 0;
                        LedgCurrCode := '';

                        case Type of
                            Type::Purchase:
                                begin
                                    SetDetailsForVendor("VAT Book Entry");
                                    VendLedgEntry.Reset();
                                    VendLedgEntry.SetCurrentKey("Document Type", "External Document No.", "Vendor No.", "Document Occurrence");
                                    VendLedgEntry.SetRange("Document Type", "Document Type");
                                    VendLedgEntry.SetRange("External Document No.", "External Document No.");
                                    VendLedgEntry.SetRange("Vendor No.", "Sell-to/Buy-from No.");
                                    if VendLedgEntry.Find('-') then
                                        if VendLedgEntry."Currency Code" <> '' then begin
                                            repeat
                                                VendLedgEntry.CalcFields(Amount);
                                                LedgAmount := LedgAmount + -VendLedgEntry.Amount;
                                            until VendLedgEntry.Next() = 0;
                                            LedgCurrCode := VendLedgEntry."Currency Code";
                                        end;
                                end;
                            Type::Sale:
                                begin
                                    if VATBookEntry."Reverse VAT Entry" then begin
                                        SetDetailsForVendor("VAT Book Entry");
                                        VendLedgEntry.Reset();
                                        VendLedgEntry.SetCurrentKey("Document Type", "External Document No.", "Vendor No.", "Document Occurrence");
                                        VendLedgEntry.SetRange("Document Type", "Document Type");
                                        VendLedgEntry.SetRange("External Document No.", "External Document No.");
                                        VendLedgEntry.SetRange("Vendor No.", "Sell-to/Buy-from No.");
                                        if VendLedgEntry.Find('-') then
                                            if VendLedgEntry."Currency Code" <> '' then begin
                                                repeat
                                                    VendLedgEntry.CalcFields(Amount);
                                                    LedgAmount += VendLedgEntry.Amount;
                                                until VendLedgEntry.Next() = 0;
                                                LedgCurrCode := VendLedgEntry."Currency Code";
                                            end;
                                    end else
                                        SetDetailsForCustomer("VAT Book Entry");
                                    CustLedgEntry.Reset();
                                    CustLedgEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Document No.", "Currency Code");
                                    CustLedgEntry.SetRange("Document Type", "Document Type");
                                    CustLedgEntry.SetRange("Customer No.", "Sell-to/Buy-from No.");
                                    CustLedgEntry.SetRange("Posting Date", "Posting Date");
                                    CustLedgEntry.SetRange("Document No.", "Document No.");
                                    CustLedgEntry.SetFilter("Currency Code", '<>%1', '');
                                    if CustLedgEntry.Find('-') then begin
                                        repeat
                                            CustLedgEntry.CalcFields(Amount);
                                            LedgAmount := LedgAmount + -CustLedgEntry.Amount;
                                        until CustLedgEntry.Next() = 0;
                                        LedgCurrCode := CustLedgEntry."Currency Code";
                                    end;
                                end;
                        end;
                        OldDocumentNo := "Document No.";
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Posting Date", '%1..%2', StartingDate, EndingDate);

                        if PrintingType <> PrintingType::Reprint then
                            SetRange("Printing Date", 0D);
                    end;
                }
                dataitem(UnrealizedVAT; "VAT Book Entry")
                {
                    CalcFields = "Document Type", Base, Amount, "VAT Calculation Type", "Sell-to/Buy-from No.", "External Document No.", "No. Series", "Nondeductible Amount", "Document Date", "VAT Difference", "Nondeductible Base", "Unrealized Base", "Unrealized Amount";
                    DataItemLink = "No. Series" = field(Code);
                    DataItemLinkReference = "No. Series";
                    DataItemTableView = sorting("Document No.", "Posting Date") order(ascending) where(Type = filter(<> Settlement), "Unrealized VAT" = filter(true));
                    column(UnrealizedVAT_PageNo_Prefix; StrSubstNo(Text1038, Format(Date2DMY(StartingDate, 3))))
                    {
                    }
                    column(UnrealizedVAT_PrintCompanyInformations; PrintCompanyInformations)
                    {
                    }
                    column(UnrealizedVAT_CompanyInformation_6; CompanyInformation[6])
                    {
                    }
                    column(DataItem1130220; CompanyInformation[1] + '    ' + CompanyInformation[2] + '    ' + CompanyInformation[3] + '    ' + Text1046 + CompanyInformation[5])
                    {
                    }
                    column(UnrealizedVAT_EndingDate; Format(EndingDate))
                    {
                    }
                    column(UnrealizedVAT_StartingDate; Format(StartingDate))
                    {
                    }
                    column(UnrealizedVAT_IntraC; IntraC)
                    {
                    }
                    column(UnrealizedVAT_VATReg; VATReg)
                    {
                    }
                    column(UnrealizedVAT_DocumentTotal; DocumentTotal)
                    {
                        AutoFormatType = 1;
                    }
                    column(Signum____Unrealized_Amount_; Signum * "Unrealized Amount")
                    {
                        AutoFormatType = 1;
                    }
                    column(Signum____Unrealized_Base_; Signum * "Unrealized Base")
                    {
                        AutoFormatType = 1;
                    }
                    column(Signum___Amount; Signum * Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(Signum___Base; Signum * Base)
                    {
                        AutoFormatType = 1;
                    }
                    column(UnrealizedVAT__VAT___; "VAT %")
                    {
                    }
                    column(UnrealizedVAT_DescrVATIdentifier; DescrVATIdentifier)
                    {
                    }
                    column(UnrealizedVAT_Name; Name)
                    {
                    }
                    column(UnrealizedVAT__Sell_to_Buy_from_No__; "Sell-to/Buy-from No.")
                    {
                    }
                    column(VATEntry__Document_No__; VATEntry."Document No.")
                    {
                    }
                    column(VATEntry__Document_Date_; Format(VATEntry."Document Date"))
                    {
                    }
                    column(UnrealizedVAT__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(UnrealizedVAT_UnrealizedVAT__Entry_No__; "Entry No.")
                    {
                    }
                    column(UnrealizedVAT_Document_No_; "Document No.")
                    {
                    }
                    column(UnrealizedVAT_No__Series; "No. Series")
                    {
                    }
                    column(Name_Control1130133Caption; Name_Control1130133CaptionLbl)
                    {
                    }
                    column(DescrVATIdentifier_Control1130132Caption; DescrVATIdentifier_Control1130132CaptionLbl)
                    {
                    }
                    column(Signum___BaseCaption; Signum___BaseCaptionLbl)
                    {
                    }
                    column(Signum___AmountCaption; Signum___AmountCaptionLbl)
                    {
                    }
                    column(Signum____Unrealized_Base_Caption; Signum____Unrealized_Base_CaptionLbl)
                    {
                    }
                    column(Signum____Unrealized_Amount_Caption; Signum____Unrealized_Amount_CaptionLbl)
                    {
                    }
                    column(DocumentTotal_Control1130126Caption; DocumentTotal_Control1130126CaptionLbl)
                    {
                    }
                    column(VATReg_Control1130125Caption; VATReg_Control1130125CaptionLbl)
                    {
                    }
                    column(IntraC_Control1130124Caption; IntraC_Control1130124CaptionLbl)
                    {
                    }
                    column(VATEntry__Document_No__Caption; VATEntry__Document_No__CaptionLbl)
                    {
                    }
                    column(VATEntry__Document_Date_Caption; VATEntry__Document_Date_CaptionLbl)
                    {
                    }
                    column(UnrealizedVAT__Posting_Date_Caption; UnrealizedVAT__Posting_Date_CaptionLbl)
                    {
                    }
                    column(Closed_Invoices_with_Unrealized_VATCaption; Closed_Invoices_with_Unrealized_VATCaptionLbl)
                    {
                    }
                    column(StartingDate_Control1130122Caption; StartingDate_Control1130122CaptionLbl)
                    {
                    }
                    column(UnrealizedVAT__Sell_to_Buy_from_No__Caption; FieldCaption("Sell-to/Buy-from No."))
                    {
                    }
                    column(UnrealizedVAT__VAT___Caption; FieldCaption("VAT %"))
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        VATBookEntry2: Record "VAT Book Entry";
                    begin
                        VATBookEntryTemp2.SetRange("Entry No.", "Entry No.");
                        if VATBookEntryTemp2.FindFirst() then
                            CurrReport.Skip();

                        if "VAT Register".Type = "VAT Register".Type::Purchase then
                            DocumentTotal := DocumentTotalCalculation("Transaction No.", "Document No.", "Unrealized VAT Entry No.")
                        else
                            DocumentTotal := -DocumentTotalCalculation("Transaction No.", "Document No.", "Unrealized VAT Entry No.");
                        VATEntry2.Get("Unrealized VAT Entry No.");
                        DocNo := VATEntry2."Document No.";
                        VATBookEntry2.Reset();
                        VATBookEntry2.SetRange("Document No.", "Document No.");
                        VATBookEntry2.SetRange(Type, Type);
                        VATBookEntry2.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                        VATBookEntry2.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                        VATBookEntry2.SetRange("VAT %", "VAT %");
                        VATBookEntry2.SetRange("Deductible %", "Deductible %");
                        VATBookEntry2.SetRange("VAT Identifier", "VAT Identifier");
                        VATBookEntry2.SetRange("Transaction No.", "Transaction No.");
                        VATBookEntry2.SetFilter("Unrealized VAT Entry No.", '<>%1', "Unrealized VAT Entry No.");
                        VATBookEntry2.SetRange("Unrealized VAT", true);
                        if VATBookEntry2.Find('-') then
                            repeat
                                VATEntry2.Get(VATBookEntry2."Unrealized VAT Entry No.");
                                if DocNo = VATEntry2."Document No." then begin
                                    VATBookEntryTemp2 := VATBookEntry2;
                                    VATBookEntryTemp2.Insert();

                                    VATBookEntry2.CalcFields(Base, Amount, "Unrealized Base", "Unrealized Amount", "Nondeductible Base",
                                      "Nondeductible Amount");
                                    Base := Base + VATBookEntry2.Base;
                                    Amount := Amount + VATBookEntry2.Amount;
                                    "Unrealized Base" := "Unrealized Base" + VATBookEntry2."Unrealized Base";
                                    "Unrealized Amount" := "Unrealized Amount" + VATBookEntry2."Unrealized Amount";
                                    "Nondeductible Base" := "Nondeductible Base" + VATBookEntry2."Nondeductible Base";
                                    "Nondeductible Amount" := "Nondeductible Amount" + VATBookEntry2."Nondeductible Amount";

                                    if "VAT Register".Type = "VAT Register".Type::Purchase then
                                        DocumentTotal := DocumentTotal +
                                          DocumentTotalCalculation(VATBookEntry2."Transaction No.",
                                            VATBookEntry2."Document No.",
                                            VATBookEntry2."Unrealized VAT Entry No.")
                                    else
                                        DocumentTotal := DocumentTotal +
                                          -DocumentTotalCalculation(VATBookEntry2."Transaction No.",
                                            VATBookEntry2."Document No.",
                                            VATBookEntry2."Unrealized VAT Entry No.");

                                    if (PrintingType = PrintingType::Final) and not PreviewRegister then begin
                                        VATBookEntry2."Printing Date" := Today;
                                        VATBookEntry2.Modify();
                                    end;
                                end;
                            until VATBookEntry2.Next() = 0;

                        VATEntry.Get("Unrealized VAT Entry No.");

                        Name := '';
                        VATReg := '';

                        if "Document Type" = "Document Type"::Invoice then
                            DocType := 'Fatt.'
                        else
                            if "Document Type" = "Document Type"::"Credit Memo" then
                                DocType := 'N.Cr.'
                            else
                                DocType := '';

                        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then begin
                            PrintLegend := true;
                            IntraC := 'I.O.';
                        end else
                            IntraC := '';

                        VATBookEntryTemp.Reset();
                        VATBookEntryTemp.SetRange("VAT Identifier", "VAT Identifier");
                        VATBookEntryTemp.SetRange("VAT %", "VAT %");
                        VATBookEntryTemp.SetRange("Deductible %", "Deductible %");

                        if VATBookEntryTemp.Find('-') then begin
                            VATBookEntryTemp.Base := VATBookEntryTemp.Base + Base;
                            VATBookEntryTemp.Amount := VATBookEntryTemp.Amount + Amount;
                            VATBookEntryTemp."Nondeductible Base" := VATBookEntryTemp."Nondeductible Base" + "Nondeductible Base";
                            VATBookEntryTemp."Nondeductible Amount" := VATBookEntryTemp."Nondeductible Amount" + "Nondeductible Amount";
                            VATBookEntryTemp."Unrealized Base" := VATBookEntryTemp."Unrealized Base" + "Unrealized Base";
                            VATBookEntryTemp."Unrealized Amount" := VATBookEntryTemp."Unrealized Amount" + "Unrealized Amount";
                            VATBookEntryTemp.Modify();
                        end else begin
                            VATBookEntryTemp.Init();
                            VATBookEntryTemp."VAT Identifier" := "VAT Identifier";
                            VATBookEntryTemp."VAT %" := "VAT %";
                            VATBookEntryTemp."Deductible %" := "Deductible %";
                            VATBookEntryTemp.Base := Base;
                            VATBookEntryTemp.Amount := Amount;
                            VATBookEntryTemp."Nondeductible Base" := "Nondeductible Base";
                            VATBookEntryTemp."Nondeductible Amount" := "Nondeductible Amount";
                            VATBookEntryTemp."Unrealized Base" := "Unrealized Base";
                            VATBookEntryTemp."Unrealized Amount" := "Unrealized Amount";
                            VATBookEntryTemp."Entry No." := "Entry No.";
                            VATBookEntryTemp.Insert();
                            VATLines := VATLines + 1;
                        end;

                        VATIdentifier.Get("VAT Identifier");
                        DescrVATIdentifier := VATIdentifier.Code;

                        if (PrintingType = PrintingType::Final) and not PreviewRegister then begin
                            VATBookEntry := UnrealizedVAT;
                            UpdateBuffer();
                            if not HasBeenMarked then
                                HasBeenMarked := true;
                            "Printing Date" := Today;
                            Modify();
                        end;

                        if Type = Type::Sale then
                            Signum := -1
                        else
                            Signum := 1;

                        if Type = Type::Sale then
                            SetDetailsForCustomer(UnrealizedVAT)
                        else
                            SetDetailsForVendor(UnrealizedVAT);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Posting Date", '%1..%2', StartingDate, EndingDate);

                        if PrintingType <> PrintingType::Reprint then
                            SetRange("Printing Date", 0D)
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                PreviewRegister := CurrReport.Preview();
                if Type = Type::Sale then begin
                    RegisterTypeSales := true;
                    RegisterTypePurchase := false;
                end else begin
                    RegisterTypeSales := false;
                    RegisterTypePurchase := true;
                end;
            end;

            trigger OnPostDataItem()
            begin
                if PrintingType = PrintingType::Final then
                    if HasBeenMarked then begin
                        "Last Printing Date" := EndingDate;
                        Modify();
                    end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Code, VATRegister.Code);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) order(ascending);
            column(Integer_PageNo_Prefix; StrSubstNo(Text1038, Format(Date2DMY(StartingDate, 3))))
            {
            }
            column(Integer_PrintCompanyInformations; PrintCompanyInformations)
            {
            }
            column(CompanyInformation_1____________CompanyInformation_2____________CompanyInformation_3______________CompanyInformation_5_; CompanyInformation[1] + '    ' + CompanyInformation[2] + '    ' + CompanyInformation[3] + '    ' + CompanyInformation[5])
            {
            }
            column(CompanyInformation_6__Control1130224; CompanyInformation[6])
            {
            }
            column(Text1038_1; StrSubstNo(Text1038, Format(Date2DMY(StartingDate, 3))))
            {
            }
            column(Companyinfo_2; CompanyInformation[1] + '    ' + CompanyInformation[2] + '    ' + CompanyInformation[3] + '    ' + Text1046 + CompanyInformation[5])
            {
            }
            column(CompanyInformation_6; CompanyInformation6)
            {
            }
            column(Integer_EndingDate; Format(EndingDate))
            {
            }
            column(Integer_StartingDate; Format(StartingDate))
            {
            }
            column(VATBookEntryTemp__VAT_Identifier_; VATBookEntryTemp."VAT Identifier")
            {
            }
            column(VATBookEntryTemp__Unrealized_Amount_; -VATBookEntryTemp."Unrealized Amount")
            {
                AutoFormatType = 1;
            }
            column(VATBookEntryTemp__Unrealized_Base_; -VATBookEntryTemp."Unrealized Base")
            {
                AutoFormatType = 1;
            }
            column(VATBookEntryTemp_Amount; -VATBookEntryTemp.Amount)
            {
                AutoFormatType = 1;
            }
            column(VATBookEntryTemp_Base_Negative; -VATBookEntryTemp.Base)
            {
                AutoFormatType = 1;
            }
            column(VATBookEntryTemp__VAT___; VATBookEntryTemp."VAT %")
            {
            }
            column(Descr; Descr)
            {
            }
            column(VATBookEntryTemp__Entry_No__; VATBookEntryTemp."Entry No.")
            {
            }
            column(VATRegister_Type; VATRegister.Type)
            {
            }
            column(RegisterSales; RegisterTypeSales)
            {
                AutoFormatType = 1;
            }
            column(VATBookEntryTemp__Nondeductible_Amount_; VATBookEntryTemp."Nondeductible Amount")
            {
                AutoFormatType = 1;
            }
            column(VATBookEntryTemp__Nondeductible_Base_; VATBookEntryTemp."Nondeductible Base")
            {
                AutoFormatType = 1;
            }
            column(VATBookEntryTemp_Amount_Control1130175; VATBookEntryTemp.Amount)
            {
                AutoFormatType = 1;
            }
            column(VATBookEntryTemp__Deductible___; VATBookEntryTemp."Deductible %")
            {
                AutoFormatType = 1;
            }
            column(VATBookEntryTemp__Unrealized_Amount__Control1130196; VATBookEntryTemp."Unrealized Amount")
            {
                AutoFormatType = 1;
            }
            column(VATBookEntryTemp__Unrealized_Base__Control1130195; VATBookEntryTemp."Unrealized Base")
            {
                AutoFormatType = 1;
            }
            column(RegisterPurchase; RegisterTypePurchase)
            {
                AutoFormatType = 1;
            }
            column(VATBookEntryTemp_Base; VATBookEntryTemp.Base)
            {
                AutoFormatType = 1;
            }
            column(PrintLegend_Control1101100012; PrintLegend)
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(StartingDate_Control1130007Caption; StartingDate_Control1130007CaptionLbl)
            {
            }
            column(Sales_VAT_Register_SummaryCaption; Sales_VAT_Register_SummaryCaptionLbl)
            {
            }
            column(Purchase_VAT_Register_SummaryCaption; Purchase_VAT_Register_SummaryCaptionLbl)
            {
            }
            column(StartingDate_Control1130013Caption; StartingDate_Control1130013CaptionLbl)
            {
            }
            column(VATBookEntryTemp_BaseCaption; VATBookEntryTemp_BaseCaptionLbl)
            {
            }
            column(VATBookEntryTemp_AmountCaption; VATBookEntryTemp_AmountCaptionLbl)
            {
            }
            column(VATBookEntryTemp__Unrealized_Amount_Caption; VATBookEntryTemp__Unrealized_Amount_CaptionLbl)
            {
            }
            column(VATBookEntryTemp__Unrealized_Base_Caption; VATBookEntryTemp__Unrealized_Base_CaptionLbl)
            {
            }
            column(VATBookEntryTemp__VAT___Caption; VATBookEntryTemp__VAT___CaptionLbl)
            {
            }
            column(DescrCaption; DescrCaptionLbl)
            {
            }
            column(VATBookEntryTemp__VAT_Identifier_Caption; VATBookEntryTemp__VAT_Identifier_CaptionLbl)
            {
            }
            column(VATBookEntryTemp__VAT_Identifier__Control1130172Caption; VATBookEntryTemp__VAT_Identifier__Control1130172CaptionLbl)
            {
            }
            column(VATBookEntryTemp__VAT____Control1130178Caption; VATBookEntryTemp__VAT____Control1130178CaptionLbl)
            {
            }
            column(VATBookEntryTemp_Base_Control1130176Caption; VATBookEntryTemp_Base_Control1130176CaptionLbl)
            {
            }
            column(VATBookEntryTemp_Amount_Control1130175Caption; VATBookEntryTemp_Amount_Control1130175CaptionLbl)
            {
            }
            column(VATBookEntryTemp__Nondeductible_Base_Caption; VATBookEntryTemp__Nondeductible_Base_CaptionLbl)
            {
            }
            column(VATBookEntryTemp__Nondeductible_Amount_Caption; VATBookEntryTemp__Nondeductible_Amount_CaptionLbl)
            {
            }
            column(Descr_Control1130179Caption; Descr_Control1130179CaptionLbl)
            {
            }
            column(VATBookEntryTemp__Deductible___Caption; VATBookEntryTemp__Deductible___CaptionLbl)
            {
            }
            column(VATBookEntryTemp__Unrealized_Base__Control1130195Caption; VATBookEntryTemp__Unrealized_Base__Control1130195CaptionLbl)
            {
            }
            column(VATBookEntryTemp__Unrealized_Amount__Control1130196Caption; VATBookEntryTemp__Unrealized_Amount__Control1130196CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(TotalCaption_Control1130147; TotalCaption_Control1130147Lbl)
            {
            }
            column(I_O____Intrac__OperationCaption; I_O____Intrac__OperationCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if FirstVATLine then
                    FirstVATLine := false
                else
                    VATBookEntryTemp.Next();

                VATIdentifier.Get(VATBookEntryTemp."VAT Identifier");
                Descr := VATIdentifier.Description;

                CompanyInformation6 := CompanyInformation[6];
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, VATLines);

                VATBookEntryTemp.Reset();
                if VATBookEntryTemp.Find('-') then;
                FirstVATLine := true;
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
                    field(VATRegister; VATRegister.Code)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Register';
                        TableRelation = "VAT Register";
                        ToolTip = 'Specifies the VAT register.';

                        trigger OnValidate()
                        begin
                            if VATRegister.Get(VATRegister.Code) then begin
                                CompanyInformation[7] := VATRegister.Description;
                                if VATRegister."Last Printing Date" <> 0D then begin
                                    StartingDate := VATRegister."Last Printing Date" + 1;
                                    ValidateDate();
                                end;
                                LastPrintedPage := VATRegister."Last Printed VAT Register Page";
                            end;
                        end;
                    }
                    field(PeriodStartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Starting Date';
                        ToolTip = 'Specifies the period starting date.';

                        trigger OnValidate()
                        begin
                            ValidateDate();
                        end;
                    }
                    field(PeriodEndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Ending Date';
                        ToolTip = 'Specifies the period ending date.';
                    }
                    field(PrintingType; PrintingType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Printing Type';
                        OptionCaption = 'Test,Final,Reprint';
                        ToolTip = 'Specifies the printing type.';
                    }
                    field(PrintCompanyInformations; PrintCompanyInformations)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Informations';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to print your company information.';
                    }
                    field(Name; CompanyInformation[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name.';
                    }
                    field(Address; CompanyInformation[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address';
                        ToolTip = 'Specifies the company''s address.';
                    }
                    field(PostCodeCityCounty; CompanyInformation[3])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Code  City  County';
                        ToolTip = 'Specifies the post code, city, and county.';
                    }
                    field(RegisterCompanyNo; CompanyInformation[4])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Register Company No.';
                        ToolTip = 'Specifies the register company number.';
                    }
                    field(VATRegistrationNo; CompanyInformation[5])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Registration No.';
                        ToolTip = 'Specifies the VAT registration number of your company or your tax representative.';
                    }
                    field(FiscalCode; CompanyInformation[6])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fiscal Code';
                        ToolTip = 'Specifies the fiscal code.';
                    }
                    field(LastPrintedPage; LastPrintedPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Last Printed VAT Register Page';
                        Editable = false;
                        ToolTip = 'Specifies the last printed page for the VAT Register report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PrintCompanyInformations := true;
            CompInfo.Get();
            CompanyInformation[1] := CompInfo.Name;
            CompanyInformation[2] := CompInfo.Address;
            CompanyInformation[3] := CompInfo."Post Code" + '  ' + CompInfo.City + '  ' + CompInfo.County;
            CompanyInformation[4] := CompInfo."Register Company No.";
            CompanyInformation[5] := CompInfo."VAT Registration No.";
            CompanyInformation[6] := CompInfo."Fiscal Code";
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
    end;

    trigger OnPostReport()
    begin
        VATBookEntryTemp.Reset();
        VATBookEntryTemp.DeleteAll();
        VATRegister.Get(VATRegister.Code);
        if (PrintingType = PrintingType::Final) and not PreviewRegister then begin
            ReprintInfo.Report := ReprintInfo.Report::"VAT Register - Print";
            ReprintInfo."Start Date" := StartingDate;
            ReprintInfo."End Date" := EndingDate;
            ReprintInfo."Vat Register Code" := "VAT Register".Code;
            if VATLines > 0 then
                ReprintInfo."First Page Number" := VATRegister."Last Printed VAT Register Page" + 1;
            // VATRegister."Last Printed VAT Register Page" := VATRegister."Last Printed VAT Register Page" + CurrReport.PAGENO - 1;

            VATRegister."Last Printing Date" := EndingDate;
            if not Confirm(Text1130040, false) then
                Error('');
            VATRegister.Modify();
            ReprintInfo.Insert();
            Message(Text12100, VATRegister.FieldCaption("Last Printed VAT Register Page"), VATRegister.TableCaption());
        end;
    end;

    trigger OnPreReport()
    var
        ITReportManagement: Codeunit "IT - Report Management";
    begin
        ITReportManagement.CheckSalesDocNoGaps(EndingDate, true, false);
        ITReportManagement.CheckPurchDocNoGaps(EndingDate, true, false);

        if VATRegister.Code = '' then
            Error(Text1130008, VATRegister.FieldCaption(Code));

        VATRegister.Get(VATRegister.Code);

        if PrintingType = PrintingType::Final then begin
            VATBookEntry.Reset();
            VATBookEntry.SetFilter("Posting Date", '<%1', StartingDate);
            VATBookEntry.SetRange("Printing Date", 0D);
            VATBookEntry.SetFilter(Type, '<>%1', VATBookEntry.Type::Settlement);
            NoSeries.Reset();
            NoSeries.SetRange("VAT Register", VATRegister.Code);
            if NoSeries.FindSet() then begin
                FirstOne := true;
                repeat
                    if FirstOne then begin
                        FilterString := FilterString + NoSeries.Code;
                        FirstOne := false;
                    end else
                        FilterString := FilterString + '|' + NoSeries.Code;
                until NoSeries.Next() = 0;
                VATBookEntry.SetFilter("No. Series", FilterString);
            end;

            if VATBookEntry.FindFirst() then
                Error(NotPrintedEntriesErr, VATBookEntry."Entry No.", VATBookEntry."Posting Date");

            if not ControlPeriod() then
                Error(Text1130034);

            if VATRegister."Last Printing Date" <> 0D then
                if Date2DMY(VATRegister."Last Printing Date", 3) <> Date2DMY(StartingDate, 3) then
                    VATRegister."Last Printed VAT Register Page" := 0;

            VATRegisterLastPrintedPageNo := GetPageNo(VATRegister."Last Printed VAT Register Page", PrintCompanyInformations);

            if EndingDate <= VATRegister."Last Printing Date" then
                if Confirm(Text1130035) then
                    PrintingType := PrintingType::Reprint
                else
                    Error(Text1130036);
        end;

        if PrintingType = PrintingType::Reprint then begin
            ReprintInfo.Get(ReprintInfo.Report::"VAT Register - Print", StartingDate, EndingDate, VATRegister.Code);
            VATRegisterLastPrintedPageNo := GetPageNo(ReprintInfo."First Page Number" - 1, PrintCompanyInformations);
        end;

        IsSales := VATRegister.Type = VATRegister.Type::Sale;

        HasBeenMarked := false;

        VATLines := 0;
        PreviewRegister := false;

        if PrintingType = PrintingType::Test then
            CompanyInformation[7] := StrSubstNo(Text1050, VATRegister.Description);
    end;

    var
        Text1130008: Label 'Please select a %1.';
        NotPrintedEntriesErr: Label 'There are entries in the previous period that were not printed.\First entry found: Entry No.: %1, Posting Date: %2.';
        Text1130034: Label 'Start Date and End Date do not correspond to begin\end of period.';
        Text1130035: Label 'This period has already been printed. Do you want to print it again?';
        Text1130036: Label 'The print has been interrupted.';
        Text1130040: Label 'Are you sure you want to print the VAT Register as final version ?';
        Text1046: Label 'VAT Reg. No. ';
        Text1038: Label 'Page %1/';
        Text1049: Label 'All Company Information related fields should be filled in on the request form.';
        Text1050: Label 'Test %1';
        Text12100: Label 'You must update the %1 field in the %2 window when you have printed the report.';
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
        NoSeries: Record "No. Series";
        VATRegister: Record "VAT Register";
        VATBookEntry: Record "VAT Book Entry";
        VATBookEntryTemp: Record "VAT Entry" temporary;
        VATIdentifier: Record "VAT Identifier";
        Date: Record Date;
        VATRegisterBuffer: Record "VAT Register - Buffer";
        VATEntry: Record "VAT Entry";
        CompInfo: Record "Company Information";
        ReprintInfo: Record "Reprint Info Fiscal Reports";
        VATEntry2: Record "VAT Entry";
        VATBookEntryTemp2: Record "VAT Book Entry" temporary;
        PrintLegend: Boolean;
        ShowFirstSection: Boolean;
        FirstOne: Boolean;
        HasBeenMarked: Boolean;
        FirstVATLine: Boolean;
        RegisterTypeSales: Boolean;
        RegisterTypePurchase: Boolean;
        PreviewRegister: Boolean;
        PrintCompanyInformations: Boolean;
        Name: Text[100];
        Descr: Text[100];
        VATReg: Text[20];
        IntraC: Text[4];
        DocType: Text[5];
        FilterString: Text[100];
        DescrVATIdentifier: Text[50];
        CompanyInformation: array[7] of Text[100];
        CompanyInformation6: Text[100];
        DocumentTotal: Decimal;
        LedgAmount: Decimal;
        LedgCurrCode: Code[10];
        OldDocumentNo: Code[20];
        DocNo: Code[20];
        PrintingType: Option Test,Final,Reprint;
        Signum: Integer;
        VATLines: Integer;
        i: Integer;
        LastPrintedPage: Integer;
        VATRegisterLastPrintedPageNo: Integer;
        StartingDate: Date;
        EndingDate: Date;
        Fiscal_Code_CaptionLbl: Label 'Fiscal Code';
        Register_Company_No_CaptionLbl: Label 'Register Company No.';
        CompanyInformation_5_CaptionLbl: Label 'VAT Reg. No.';
        StartingDateCaptionLbl: Label 'Period:';
        DocumentTotalCaptionLbl: Label 'Total';
        VATRegCaptionLbl: Label 'VAT Registration No.';
        IntraCCaptionLbl: Label 'Intra Com';
        Unrealized_Amount_CaptionLbl: Label 'Unrealized Amount';
        Unrealized_Base_CaptionLbl: Label 'Unrealized Base';
        AmountCaptionLbl: Label 'Amount';
        BaseCaptionLbl: Label 'Base';
        DescrVATIdentifierCaptionLbl: Label 'VAT Prod. Description';
        NameCaptionLbl: Label 'Customer';
        VAT_Book_Entry__Document_Date_CaptionLbl: Label 'Document Date';
        VAT_Book_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Sales_VAT_RegisterCaptionLbl: Label 'Sales VAT Register';
        VATReg_Control1130066CaptionLbl: Label 'VAT Registration No.';
        IntraC_Control1130065CaptionLbl: Label 'Intra Com';
        DocumentTotal_Control1130069CaptionLbl: Label 'Total';
        DescrVATIdentifier_Control1130074CaptionLbl: Label 'VAT Prod. Description';
        Name_Control1130075CaptionLbl: Label 'Vendor';
        VAT_Book_Entry__Sell_to_Buy_from_No___Control1130076CaptionLbl: Label 'Code';
        DocTypeCaptionLbl: Label 'Doc. Type';
        VAT_Book_Entry__External_Document_No__CaptionLbl: Label 'External Doc. No.';
        VAT_Book_Entry__Document_Date__Control1130080CaptionLbl: Label 'Doc. Date';
        VAT_Book_Entry__Posting_Date__Control1130081CaptionLbl: Label 'Posting Date';
        StartingDate_Control1130062CaptionLbl: Label 'Period:';
        Purchase_VAT_RegisterCaptionLbl: Label 'Purchase VAT Register';
        LedgCurrCodeCaptionLbl: Label 'Currency Code';
        LedgAmountCaptionLbl: Label 'Currency Amount';
        LedgCurrCode_Control1130102CaptionLbl: Label 'Currency Code';
        LedgAmount_Control1130104CaptionLbl: Label 'Currency Amount';
        Name_Control1130133CaptionLbl: Label 'Customer';
        DescrVATIdentifier_Control1130132CaptionLbl: Label 'VAT Prod. Description';
        Signum___BaseCaptionLbl: Label 'Base';
        Signum___AmountCaptionLbl: Label 'Amount';
        Signum____Unrealized_Base_CaptionLbl: Label 'Unrealized Base';
        Signum____Unrealized_Amount_CaptionLbl: Label 'Unrealized Amount';
        DocumentTotal_Control1130126CaptionLbl: Label 'Total';
        VATReg_Control1130125CaptionLbl: Label 'VAT Registration No.';
        IntraC_Control1130124CaptionLbl: Label 'Intra Com';
        VATEntry__Document_No__CaptionLbl: Label 'Document No.';
        VATEntry__Document_Date_CaptionLbl: Label 'Document Date';
        UnrealizedVAT__Posting_Date_CaptionLbl: Label 'Posting Date';
        Closed_Invoices_with_Unrealized_VATCaptionLbl: Label 'Closed Invoices with Unrealized VAT';
        StartingDate_Control1130122CaptionLbl: Label 'Period:';
        StartingDate_Control1130007CaptionLbl: Label 'Period:';
        Sales_VAT_Register_SummaryCaptionLbl: Label 'Sales VAT Register Summary';
        Purchase_VAT_Register_SummaryCaptionLbl: Label 'Purchase VAT Register Summary';
        StartingDate_Control1130013CaptionLbl: Label 'Period:';
        VATBookEntryTemp_BaseCaptionLbl: Label 'VAT Base';
        VATBookEntryTemp_AmountCaptionLbl: Label 'VAT Amount';
        VATBookEntryTemp__Unrealized_Amount_CaptionLbl: Label 'Unrealized Amount';
        VATBookEntryTemp__Unrealized_Base_CaptionLbl: Label 'Unrealized Base';
        VATBookEntryTemp__VAT___CaptionLbl: Label 'VAT %';
        DescrCaptionLbl: Label 'Description';
        VATBookEntryTemp__VAT_Identifier_CaptionLbl: Label 'VAT Identifier';
        VATBookEntryTemp__VAT_Identifier__Control1130172CaptionLbl: Label 'VAT Identifier';
        VATBookEntryTemp__VAT____Control1130178CaptionLbl: Label 'VAT %';
        VATBookEntryTemp_Base_Control1130176CaptionLbl: Label 'VAT Base';
        VATBookEntryTemp_Amount_Control1130175CaptionLbl: Label 'VAT Amount';
        VATBookEntryTemp__Nondeductible_Base_CaptionLbl: Label 'Nondeductible Base';
        VATBookEntryTemp__Nondeductible_Amount_CaptionLbl: Label 'Nondeductible Amount';
        Descr_Control1130179CaptionLbl: Label 'Description';
        VATBookEntryTemp__Deductible___CaptionLbl: Label 'Deductible %';
        VATBookEntryTemp__Unrealized_Base__Control1130195CaptionLbl: Label 'Unrealized Base';
        VATBookEntryTemp__Unrealized_Amount__Control1130196CaptionLbl: Label 'Unrealized Amount';
        TotalCaptionLbl: Label 'Total';
        TotalCaption_Control1130147Lbl: Label 'Total';
        I_O____Intrac__OperationCaptionLbl: Label 'I.O. = Intrac. Operation';
        IsSales: Boolean;

    [Scope('OnPrem')]
    procedure DocumentTotalCalculation(TransactionNo: Integer; DocNo: Code[20]; UnrVatEntryNo: Integer): Decimal
    var
        LocalTotDoc: Decimal;
    begin
        LocalTotDoc := 0;

        VATBookEntry.Reset();
        VATBookEntry.SetRange("Transaction No.", TransactionNo);
        VATBookEntry.SetRange("No. Series", "No. Series".Code);
        VATBookEntry.SetRange("Document No.", DocNo);
        VATBookEntry.SetRange("Unrealized VAT Entry No.", UnrVatEntryNo);

        if VATBookEntry.Find('-') then
            repeat
                VATBookEntry.CalcFields(Base, Amount, "Unrealized Amount", "Unrealized Base", "Nondeductible Base",
                  "Nondeductible Amount");
                LocalTotDoc := LocalTotDoc + VATBookEntry.Base + VATBookEntry.Amount +
                  VATBookEntry."Unrealized Amount" +
                  VATBookEntry."Unrealized Base" +
                  VATBookEntry."Nondeductible Base" +
                  VATBookEntry."Nondeductible Amount";
            until VATBookEntry.Next() = 0;

        exit(LocalTotDoc);
    end;

    [Scope('OnPrem')]
    procedure ControlPeriod() SamePeriod: Boolean
    begin
        // Correct = TRUE : datafine deve coincidere con fine periodo
        // Correct = FALSE : datainizio deve essere <= fine periodo

        SamePeriod := false;
        Date.Reset();

        if EndingDate < StartingDate then
            exit;

        case GLSetup."VAT Settlement Period" of
            GLSetup."VAT Settlement Period"::Month:
                Date.Get(Date."Period Type"::Month, StartingDate);
            GLSetup."VAT Settlement Period"::Quarter:
                Date.Get(Date."Period Type"::Quarter, StartingDate);
        end;
        if NormalDate(Date."Period End") = EndingDate then
            SamePeriod := true;
    end;

    [Scope('OnPrem')]
    procedure ValidateDate()
    var
        PeriodType: Option;
    begin
        case GLSetup."VAT Settlement Period" of
            GLSetup."VAT Settlement Period"::Month:
                PeriodType := Date."Period Type"::Month;
            GLSetup."VAT Settlement Period"::Quarter:
                PeriodType := Date."Period Type"::Quarter;
        end;
        if Date.Get(PeriodType, StartingDate) then
            if Date.Find('>') then
                EndingDate := Date."Period Start" - 1;
    end;

    [Scope('OnPrem')]
    procedure UpdateBuffer()
    begin
        VATRegisterBuffer.Reset();
        VATRegisterBuffer.SetRange("Period Start Date", StartingDate);
        VATRegisterBuffer.SetRange("Period End Date", EndingDate);
        VATRegisterBuffer.SetRange("VAT Register Code", VATRegister.Code);
        VATRegisterBuffer.SetRange("Register Type", VATRegister.Type);
        VATRegisterBuffer.SetRange("VAT Identifier", VATBookEntry."VAT Identifier");
        VATRegisterBuffer.SetRange("VAT Deductible %", VATBookEntry."Deductible %");
        VATRegisterBuffer.SetRange("VAT %", VATBookEntry."VAT %");

        if VATRegisterBuffer.FindFirst() then begin
            VATRegisterBuffer.Base := VATRegisterBuffer.Base + VATBookEntry.Base;
            VATRegisterBuffer.Amount := VATRegisterBuffer.Amount + VATBookEntry.Amount;
            VATRegisterBuffer."Nondeductible Base" := VATRegisterBuffer."Nondeductible Base" + VATBookEntry."Nondeductible Base";
            VATRegisterBuffer."Nondeductible Amount" := VATRegisterBuffer."Nondeductible Amount" + VATBookEntry."Nondeductible Amount";
            VATRegisterBuffer."Unrealized Base" := VATRegisterBuffer."Unrealized Base" + VATBookEntry."Unrealized Base";
            VATRegisterBuffer."Unrealized Amount" := VATRegisterBuffer."Unrealized Amount" + VATBookEntry."Unrealized Amount";
            VATRegisterBuffer.Modify();
        end else begin
            VATRegisterBuffer.Init();
            VATRegisterBuffer."Period Start Date" := StartingDate;
            VATRegisterBuffer."Period End Date" := EndingDate;
            VATRegisterBuffer."VAT Register Code" := VATRegister.Code;
            VATRegisterBuffer."Register Type" := VATRegister.Type;
            VATRegisterBuffer."VAT Prod. Posting Group" := VATBookEntry."VAT Prod. Posting Group";
            VATRegisterBuffer."VAT Deductible %" := VATBookEntry."Deductible %";
            VATRegisterBuffer."VAT %" := VATBookEntry."VAT %";
            VATRegisterBuffer."VAT Identifier" := VATBookEntry."VAT Identifier";
            VATRegisterBuffer.Base := VATBookEntry.Base;
            VATRegisterBuffer.Amount := VATBookEntry.Amount;
            VATRegisterBuffer."Nondeductible Base" := VATBookEntry."Nondeductible Base";
            VATRegisterBuffer."Nondeductible Amount" := VATBookEntry."Nondeductible Amount";
            VATRegisterBuffer."Unrealized Base" := VATBookEntry."Unrealized Base";
            VATRegisterBuffer."Unrealized Amount" := VATBookEntry."Unrealized Amount";
            VATRegisterBuffer.Insert();
        end;
    end;

    procedure InitializeRequest(NewVATRegister: Record "VAT Register"; NewPrintingType: Option; NewStartDate: Date; NewEndDate: Date; NewPrintCompanyInfo: Boolean; NewCompanyInformation: array[7] of Text[100])
    var
        I: Integer;
    begin
        VATRegister := NewVATRegister;
        PrintingType := NewPrintingType;
        StartingDate := NewStartDate;
        EndingDate := NewEndDate;
        PrintCompanyInformations := NewPrintCompanyInfo;
        for I := 1 to 7 do
            CompanyInformation[I] := NewCompanyInformation[I];
    end;

    local procedure SetDetailsForCustomer(VATBookEntry: Record "VAT Book Entry")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        VATReg := GetCustomerVatRegistrationNo(VATBookEntry."Sell-to/Buy-from No.", VATBookEntry."Entry No.");
        Name := GetCustomerName(VATBookEntry."Sell-to/Buy-from No.");

        case VATBookEntry."Document Type" of
            VATBookEntry."Document Type"::Invoice:
                if SalesInvHeader.Get(VATBookEntry."Document No.") then
                    Name := SalesInvHeader."Bill-to Name"
                else
                    OnSetDetailsForCustomerInvoice(VATBookEntry, Name);
            VATBookEntry."Document Type"::"Credit Memo":
                if SalesCrMemoHeader.Get(VATBookEntry."Document No.") then
                    Name := SalesCrMemoHeader."Bill-to Name"
                else
                    OnSetDetailsForCustomerCrMemo(VATBookEntry, Name);
        end;
    end;

    local procedure SetDetailsForVendor(VATBookEntry: Record "VAT Book Entry")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        VATReg := GetVendorVatRegistrationNo(VATBookEntry."Sell-to/Buy-from No.", VATBookEntry."Entry No.");
        Name := GetVendorName(VATBookEntry."Sell-to/Buy-from No.");

        case VATBookEntry."Document Type" of
            VATBookEntry."Document Type"::Invoice:
                if PurchInvHeader.Get(VATBookEntry."Document No.") then
                    Name := PurchInvHeader."Pay-to Name";
            VATBookEntry."Document Type"::"Credit Memo":
                if PurchCrMemoHeader.Get(VATBookEntry."Document No.") then
                    Name := PurchCrMemoHeader."Pay-to Name";
        end;
    end;

    local procedure GetVendorName(VendorNo: Code[20]): Text[100]
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit(Vendor.Name);
    end;

    local procedure GetCustomerName(CustomerNo: Code[20]): Text[100]
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            exit(Customer.Name);
    end;

    local procedure GetVendorVatRegistrationNo(VendorNo: Code[20]; VATEntryNo: Integer): Text[20]
    var
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then begin
            if Vendor.Resident = Vendor.Resident::Resident then
                exit(Vendor."VAT Registration No.");

            VATEntry.Get(VATEntryNo);
            if VATEntry."Tax Representative No." = '' then
                exit(GetVATRegNoOfTaxRepresentative(Vendor."Tax Representative Type", Vendor."Tax Representative No."));
            exit(GetVATRegNoOfTaxRepresentative(VATEntry."Tax Representative Type", VATEntry."Tax Representative No."));
        end;
    end;

    local procedure GetVATRegNoOfTaxRepresentative(TaxRepresentativeType: Option; TaxRepresentativeNo: Code[20]): Text
    var
        TaxRepresentativeVendor: Record Vendor;
        TaxRepresentativeCustomer: Record Customer;
        TaxRepresentativeContact: Record Contact;
        VATEntry: Record "VAT Entry";
    begin
        case TaxRepresentativeType of
            VATEntry."Tax Representative Type"::Vendor:
                if TaxRepresentativeVendor.Get(TaxRepresentativeNo) then
                    exit(TaxRepresentativeVendor."VAT Registration No.");
            VATEntry."Tax Representative Type"::Customer:
                if TaxRepresentativeCustomer.Get(TaxRepresentativeNo) then
                    exit(TaxRepresentativeCustomer."VAT Registration No.");
            VATEntry."Tax Representative Type"::Contact:
                if TaxRepresentativeContact.Get(TaxRepresentativeNo) then
                    exit(TaxRepresentativeContact."VAT Registration No.");
        end;
    end;

    local procedure GetCustomerVatRegistrationNo(CustomerNo: Code[20]; VATEntryNo: Integer): Text[20]
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then begin
            if Customer.Resident = Customer.Resident::Resident then
                exit(Customer."VAT Registration No.");

            VATEntry.Get(VATEntryNo);
            if VATEntry."Tax Representative No." = '' then
                exit(GetVATRegNoOfTaxRepresentative(Customer."Tax Representative Type", Customer."Tax Representative No."));
            exit(GetVATRegNoOfTaxRepresentative(VATEntry."Tax Representative Type", VATEntry."Tax Representative No."));
        end;
    end;

    local procedure GetPageNo(PageNo: Integer; PrintCompanyInfo: Boolean): Integer
    begin
        if PrintCompanyInfo then
            PageNo -= 1;
        exit(PageNo);
    end;

    local procedure IsForeignCV(VATBookEntry: Record "VAT Book Entry"): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        CountryRegionCode: Code[10];
    begin
        case VATBookEntry.Type of
            VATBookEntry.Type::Settlement:
                exit(false);
            VATBookEntry.Type::Sale:
                if Customer.Get(VATBookEntry."Sell-to/Buy-from No.") then
                    CountryRegionCode := Customer."Country/Region Code";
            VATBookEntry.Type::Purchase:
                if Vendor.Get(VATBookEntry."Sell-to/Buy-from No.") then
                    CountryRegionCode := Vendor."Country/Region Code";
        end;
        exit((CountryRegionCode <> '') and (CountryRegionCode <> CompInfo."Country/Region Code"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetDetailsForCustomerInvoice(var VATBookEntry: Record "VAT Book Entry"; var Name: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetDetailsForCustomerCrMemo(var VATBookEntry: Record "VAT Book Entry"; var Name: Text[100])
    begin
    end;
}

