// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;

report 11509 "Vendor Payment Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/VendorPaymentOrder.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Order';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(CompanyInfoAddr; CompanyInformation.Address)
            {
            }
            column(CompanyInfoPostCodeCity; CompanyInformation."Post Code" + ' ' + CompanyInformation.City)
            {
            }
            column(CompanyInfoPhoneNo; CompanyInformation."Phone No.")
            {
            }
            column(VendName; Vendor.Name)
            {
            }
            column(CurrCode_GenJnlLine; "Currency Code")
            {
            }
            column(ExternalDocNo_GenJnlLine; "External Document No.")
            {
            }
            column(Amt_GenJnlLine; Amount)
            {
            }
            column(Pos; Pos)
            {
            }
            column(Text1; Text1)
            {
            }
            column(BankAccNo; BankAccNo)
            {
            }
            column(ShowAdrLines; ShowAdrLines)
            {
            }
            column(AppliesToDocNo_GenJnlLine; "Applies-to Doc. No.")
            {
            }
            column(DocNo_GenJnlLine; "Document No.")
            {
            }
            column(VendAddr; Vendor.Address)
            {
            }
            column(VendPostCodeCity; Vendor."Post Code" + ' ' + Vendor.City)
            {
            }
            column(Text2; Text2)
            {
            }
            column(VendBankName; VendBank.Name)
            {
            }
            column(VendBankPostCodeCity; VendBank."Post Code" + ' ' + VendBank.City)
            {
            }
            column(CompanyInfoBankName; CompanyInformation."Bank Name")
            {
            }
            column(CompanyInfoBankAcc; CompanyInfoBankAcc)
            {
            }
            column(DebitDate; Format(DebitDate))
            {
            }
            column(AmtLCY_GenJnlLine; "Amount (LCY)")
            {
            }
            column(CompanyInfoCityTodayFormatted; CompanyInformation.City + ', ' + Format(Today))
            {
            }
            column(GlSetupLCYCode; GlSetup."LCY Code")
            {
            }
            column(PymtOrderCaption; PymtOrderCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(PhoneCaption; PhoneCaptionLbl)
            {
            }
            column(AmtCaption_GenJnlLine; FieldCaption(Amount))
            {
            }
            column(CurrCodeCaption_GenJnlLine; FieldCaption("Currency Code"))
            {
            }
            column(GenJnlLineExternalDocNoCaption; GenJnlLineExternalDocNoCaptionLbl)
            {
            }
            column(Text1Caption; Text1CaptionLbl)
            {
            }
            column(BankAccNoCaption; BankAccNoCaptionLbl)
            {
            }
            column(VendNameCaption; VendNameCaptionLbl)
            {
            }
            column(PosCaption; PosCaptionLbl)
            {
            }
            column(DebitAcctCaption; DebitAcctCaptionLbl)
            {
            }
            column(DebitDateCaption; DebitDateCaptionLbl)
            {
            }
            column(CityDateCaption; CityDateCaptionLbl)
            {
            }
            column(SignatureCaption; SignatureCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(JnlTemplateName_GenJnlLine; "Journal Template Name")
            {
            }
            column(JnlBatchName_GenJnlLine; "Journal Batch Name")
            {
            }
            column(LineNo_GenJnlLine; "Line No.")
            {
            }

            trigger OnAfterGetRecord()
            begin
                BankAccNo := '';

                Pos := Pos + 1;
                if not Vendor.Get("Gen. Journal Line"."Account No.") then
                    Vendor.Init();

                // Split text at space before pos 30
                if StrLen(Description) > 30 then begin
                    i := 30;

                    repeat
                        i := i - 1;
                    until CopyStr(Description, i, 1) = ' ';

                    Text1 := CopyStr(Description, 1, i);
                    Text2 := CopyStr(Description, i + 1, 30);
                end else begin
                    Text1 := Format(Description, -MaxStrLen(Text1));
                    Text2 := '';
                end;

                if "Recipient Bank Account" <> '' then
                    VendBank.Get("Account No.", "Recipient Bank Account")
                else
                    VendBank.Get(Vendor."No.", Vendor."Preferred Bank Account Code");

                if VendBank.IBAN <> '' then
                    BankAccNo := VendBank.IBAN
                else begin
                    if VendBank."Giro Account No." <> '' then
                        GiroAccTxt := VendBank."Giro Account No."
                    else
                        GiroAccTxt := VendBank."ESR Account No.";

                    if VendBank."Clearing No." = '' then
                        VendBank."Clearing No." := Format(VendBank."Bank Identifier Code", -MaxStrLen(VendBank."Clearing No."));

                    BankAccNo := Format(VendBank."Bank Account No." + '  ' + GiroAccTxt + '  ' + VendBank."Clearing No.", -50)
                end;
            end;

            trigger OnPreDataItem()
            begin
                GlSetup.Get();

                // Only vendor payment lines of selected journal
                "Gen. Journal Line".SetRange("Journal Batch Name", JourName);
                "Gen. Journal Line".SetRange("Account Type", "Gen. Journal Line"."Account Type"::Vendor);
                "Gen. Journal Line".SetRange("Document Type", "Gen. Journal Line"."Document Type"::Payment);
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
                    field(JourName; JourName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Batch Name';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the journal batch.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(PAGE::"General Journal Batches", GenJourBatch) = ACTION::LookupOK then
                                JourName := GenJourBatch.Name;
                        end;
                    }
                    field(DebitDate; DebitDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Debit Date';
                        ToolTip = 'Specifies the debit date that you want to use on the payment order.';
                    }
                    field(ShowAdrLines; ShowAdrLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Address Lines';
                        ToolTip = 'Specifies if you want the payment order to show address lines.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
            GenJournalTemplate.SetRange(Recurring, false);
            if not GenJournalTemplate.Find('-') then
                Error(Text000);
            GenJourBatch.FilterGroup(2);
            GenJourBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
            GenJourBatch.FilterGroup(0);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();

        if CompanyInformation.IBAN <> '' then
            CompanyInfoBankAcc := CompanyInformation.IBAN
        else
            CompanyInfoBankAcc := CompanyInformation."Bank Account No.";
    end;

    var
        GlSetup: Record "General Ledger Setup";
        GenJourBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        VendBank: Record "Vendor Bank Account";
        JourName: Code[10];
        ShowAdrLines: Boolean;
        DebitDate: Date;
        Pos: Integer;
        i: Integer;
        Text1: Text[30];
        Text2: Text[30];
        GiroAccTxt: Text[20];
        Text000: Label 'There is no Payment Template.';
        BankAccNo: Text[50];
        CompanyInfoBankAcc: Text[50];
        PymtOrderCaptionLbl: Label 'Payment Order';
        PageNoCaptionLbl: Label 'Page';
        PhoneCaptionLbl: Label 'Phone';
        GenJnlLineExternalDocNoCaptionLbl: Label 'Doc. no.';
        Text1CaptionLbl: Label 'Text';
        BankAccNoCaptionLbl: Label 'Acc. No / Clearing / IBAN';
        VendNameCaptionLbl: Label 'Beneficiary';
        PosCaptionLbl: Label 'Pos.';
        DebitAcctCaptionLbl: Label 'Debit Account';
        DebitDateCaptionLbl: Label 'Debit Date';
        CityDateCaptionLbl: Label 'City / Date';
        SignatureCaptionLbl: Label 'Signature';
        TotalCaptionLbl: Label 'Total';
}

