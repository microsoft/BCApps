// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 10703 "Vendor - Annual Declaration"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorAnnualDeclaration.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Annual Declaration';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            CalcFields = "Inv. Amounts (LCY)", "Cr. Memo Amounts (LCY)";
            RequestFilterFields = "No.", "Vendor Posting Group", "Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Vendor_TABLECAPTION__________VendFilter; Vendor.TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(Text1100000___FORMAT_MinAmount_; Text1100000 + Format(MinAmount))
            {
            }
            column(GroupNo; GroupNo)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(VendAddr_1_; VendAddr[1])
            {
            }
            column(VendAddr_2_; VendAddr[2])
            {
            }
            column(VendAddr_3_; VendAddr[3])
            {
            }
            column(VendAddr_4_; VendAddr[4])
            {
            }
            column(VendAddr_5_; VendAddr[5])
            {
            }
            column(VendAddr_6_; VendAddr[6])
            {
            }
            column(VendAddr_7_; VendAddr[7])
            {
            }
            column(Vendor__VAT_Registration_No__; "VAT Registration No.")
            {
            }
            column(PurchaseAmt; PurchaseAmt)
            {
                DecimalPlaces = 0 : 2;
            }
            column(VendAddr_8_; VendAddr[8])
            {
            }
            column(AcumPurchasesAmount; AcumPurchasesAmount)
            {
                DecimalPlaces = 0 : 2;
            }
            column(Vendors___Annual_DeclarationCaption; Vendors___Annual_DeclarationCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor__No__Caption; FieldCaption("No."))
            {
            }
            column(Vendor__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
            {
            }
            column(Name_and_AddressCaption; Name_and_AddressCaptionLbl)
            {
            }
            column(PurchaseAmtCaption; PurchaseAmtCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                IgnoreAmt: Decimal;
                InvoiceAmt: Decimal;
                CrMemoAmt: Decimal;
            begin
                IgnoreAmt := 0;
                PurchaseAmt := 0;
                InvoiceAmt := 0;
                CrMemoAmt := 0;
                VendEntries.SetCurrentKey("Document Type", "Vendor No.", "Posting Date", "Currency Code");

                VendEntries.SetRange("Document Type", VendEntries."Document Type"::Invoice, VendEntries."Document Type"::"Credit Memo");
                VendEntries.SetRange("Vendor No.", "No.");
                VendEntries.SetRange("Posting Date", GetRangeMin("Date Filter"), GetRangeMax("Date Filter"));
                if VendEntries.Find('-') then
                    repeat
                        case VendEntries."Document Type" of
                            VendEntries."Document Type"::Invoice:
                                InvoiceAmt := InvoiceAmt - CalcTotalPurchAmt(VendEntries."Entry No.");
                            VendEntries."Document Type"::"Credit Memo":
                                CrMemoAmt := CrMemoAmt + CalcTotalPurchAmt(VendEntries."Entry No.");
                        end;
                        GLEntries.SetCurrentKey("Document No.", "Posting Date");
                        GLEntries.SetRange("Document No.", VendEntries."Document No.");
                        GLEntries.SetRange("Posting Date", VendEntries."Posting Date");
                        GLEntries.SetRange("Gen. Posting Type", GLEntries."Gen. Posting Type"::Purchase);
                        if GLEntries.Find('-') then
                            repeat
                                Account.Get(GLEntries."G/L Account No.");
                                if Account."Ignore in 347 Report" then
                                    IgnoreAmt := IgnoreAmt + GLEntries.Amount + GLEntries."VAT Amount";
                            until GLEntries.Next() = 0;
                    until VendEntries.Next() = 0;
                PurchaseAmt := InvoiceAmt - CrMemoAmt;
                if PurchaseAmt <= MinAmount then
                    CurrReport.Skip();

                PurchaseAmt := PurchaseAmt - IgnoreAmt;

                AcumPurchasesAmount := AcumPurchasesAmount + PurchaseAmt;
                FormatAddress.FormatAddr(
                  VendAddr, Name, "Name 2", '', Address, "Address 2",
                  City, "Post Code", County, "Country/Region Code");

                if (GroupNo = 0) and (Counter = 0) then
                    Counter := Counter + 1;
                if Counter = BlocksPerPage then begin
                    GroupNo := GroupNo + 1;
                    Counter := 0;
                end;
                Counter := Counter + 1;
            end;

            trigger OnPreDataItem()
            begin
                BlocksPerPage := 6;
                Counter := 0;
                GroupNo := 0;
            end;
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
                    field(MinAmount; MinAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amounts greater than';
                        ToolTip = 'Specifies the invoice amount that the vendor must exceed to appear in the report.';
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

    trigger OnPreReport()
    begin
        VendFilter := Vendor.GetFilters();
    end;

    var
        Text1100000: Label 'Amounts greater than ';
        VendEntries: Record "Vendor Ledger Entry";
        GLEntries: Record "G/L Entry";
        Account: Record "G/L Account";
        FormatAddress: Codeunit "Format Address";
        VendFilter: Text[250];
        VendAddr: array[8] of Text[100];
        PurchaseAmt: Decimal;
        MinAmount: Decimal;
        AcumPurchasesAmount: Decimal;
        GroupNo: Integer;
        Counter: Integer;
        BlocksPerPage: Integer;
        Vendors___Annual_DeclarationCaptionLbl: Label 'Vendors - Annual Declaration';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Name_and_AddressCaptionLbl: Label 'Name and Address';
        PurchaseAmtCaptionLbl: Label 'Amount (LCY)';

    [Scope('OnPrem')]
    procedure CalcTotalPurchAmt(EntryNo: Integer) TotalPurchAmt: Decimal
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.Reset();
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", EntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::"Initial Entry");
        DtldVendLedgEntry.CalcSums("Amount (LCY)");
        exit(DtldVendLedgEntry."Amount (LCY)");
    end;
}

