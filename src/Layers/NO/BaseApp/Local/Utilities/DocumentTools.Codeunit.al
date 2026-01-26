// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using System.IO;

codeunit 10601 DocumentTools
{

    trigger OnRun()
    begin
    end;

    var
        AmountKr: Integer;
        Amountkre: Integer;
        KIDDocumentNo: Text[24];
        KIDCustomerNo: Text[24];
        KIDDocType: Text[1];
        KIDSetupErr: Label 'If KID is used on the finance charge memo or reminder, then the KID setup has to be %1 or %2.', Comment = '%1 - type1, %2 - type2';
        KundeIDTxt: Label 'KID', Comment = 'Customer ID';

    procedure SetupGiro(PrintGiro: Boolean; DocumentType: Integer; DocumentNo: Code[20]; CustomerNo: Code[20]; GiroAmount: Decimal; GiroCurrencyCode: Code[10]; var GiroAmountKr: Text[20]; var GiroAmountkre: Text[2]; var CheckDigit: Text[1]; var GiroKID: Text[25]; var KIDError: Boolean)
    var
        AmountControl: Text[25];
    begin
        if not PrintGiro then begin
            // Format amount on pages before the last
            GiroAmountKr := '***';
            GiroAmountkre := '**';
            CheckDigit := ' ';
            GiroKID := '';
        end else begin
            // Format amount on the last page
            if GiroCurrencyCode <> '' then begin
                // Currency not possible. Blank amounts
                GiroAmountKr := '';
                GiroAmountkre := '';
                CheckDigit := ' ';
            end else begin
                GiroAmount := Abs(GiroAmount);
                AmountKr := Round(GiroAmount, 1, '<');
                Amountkre := (GiroAmount - AmountKr) * 100;
                GiroAmountKr := StrSubstNo('%1', AmountKr);
                if Amountkre = 0 then
                    GiroAmountkre := '00';
                if Amountkre < 10 then
                    GiroAmountkre := StrSubstNo('0%1', Amountkre);
                if Amountkre >= 10 then
                    GiroAmountkre := StrSubstNo('%1', Amountkre);
                AmountControl := GiroAmountKr + GiroAmountkre;
                CheckDigit := Modulus10(AmountControl);
            end;

            // Test if KID has to be used
            GenerateGiroKID(DocumentType, DocumentNo, CustomerNo, GiroKID, KIDError);
        end;
    end;

    procedure GenerateGiroKID(DocumentType: Integer; DocumentNo: Code[20]; CustomerNo: Code[20]; var GiroKID: Text[25]; var KIDError: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        case true of
            (SalesSetup."KID Setup" = SalesSetup."KID Setup"::"Do not use"):
                GiroKID := '';
            (DocumentType = 2) and (not SalesSetup."Use KID on Fin. Charge Memo"):
                GiroKID := '';
            (DocumentType = 3) and (not SalesSetup."Use KID on Reminder"):
                GiroKID := '';
            not KIDTextOK(DocumentNo, SalesSetup."Document No. length", KIDError):
                GiroKID := '';
            else
                // Format KID
                SalesSetup.TestField("Document No. length");
                KIDDocumentNo :=
                  Format(DocumentNo, 0,
                    StrSubstNo('<text,%1><filler character,0>', SalesSetup."Document No. length"));
                KIDDocType := Format(DocumentType);
                if SalesSetup."Customer No. length" > 0 then
                    KIDCustomerNo :=
                      Format(CustomerNo, 0,
                        StrSubstNo('<text,%1><filler character,0>', SalesSetup."Customer No. length"));

                case SalesSetup."KID Setup" of
                    SalesSetup."KID Setup"::"Document No.":
                        GiroKID := KIDDocumentNo;
                    SalesSetup."KID Setup"::"Document No.+Customer No.":
                        GiroKID := CopyStr(KIDDocumentNo + KIDCustomerNo, 1, MaxStrLen(GiroKID) - 1);
                    SalesSetup."KID Setup"::"Customer No.+Document No.":
                        GiroKID := CopyStr(KIDCustomerNo + KIDDocumentNo, 1, MaxStrLen(GiroKID) - 1);
                    SalesSetup."KID Setup"::"Document Type+Document No.":
                        GiroKID := CopyStr(KIDDocType + KIDDocumentNo, 1, MaxStrLen(GiroKID) - 1);
                    SalesSetup."KID Setup"::"Document No.+Document Type":
                        GiroKID := CopyStr(KIDDocumentNo + KIDDocType, 1, MaxStrLen(GiroKID) - 1);
                end;
                GiroKID := GiroKID + Modulus10(GiroKID);
        end;
    end;

    procedure KIDTextOK(KIDText: Text[30]; MaxLength: Integer; var KIDError: Boolean): Boolean
    var
        NoOK: Boolean;
        i: Integer;
    begin
        NoOK := true;
        if StrLen(KIDText) > MaxLength then
            NoOK := false;
        // Only digits allowed
        for i := 1 to StrLen(KIDText) do
            if StrPos('0123456789', CopyStr(KIDText, i, 1)) = 0 then
                NoOK := false;

        if not NoOK then
            KIDError := true;
        exit(NoOK);
    end;

    procedure Modulus10(KIDText: Text[25]): Text[1]
    var
        TempText: Text[60];
        Digit: Integer;
        i: Integer;
    begin
        TempText := '0000000000000000000000000' + KIDText + '0';
        KIDText := CopyStr(TempText, StrLen(TempText) - 24);
        for i := 1 to 12 do begin
            Evaluate(Digit, CopyStr(KIDText, i * 2, 1));
            Digit := Digit * 2;
            if Digit > 10 then begin
                TempText := Format(Digit);
                Digit := 99 - StrCheckSum(TempText, '11', 99);
            end;
            TempText := Format(Digit);
            KIDText[i * 2] := TempText[1];
        end;
        // Calculate control digit
        exit(StrSubstNo('%1', StrCheckSum(KIDText, '1111111111111111111111111', 10)));
    end;

    procedure TestKIDSetup(SRSetup: Record "Sales & Receivables Setup")
    var
        SRSetup1: Record "Sales & Receivables Setup";
        SRSetup2: Record "Sales & Receivables Setup";
    begin
        SRSetup1."KID Setup" := SRSetup1."KID Setup"::"Document Type+Document No.";
        SRSetup2."KID Setup" := SRSetup2."KID Setup"::"Document No.+Document Type";
        if (SRSetup."Use KID on Fin. Charge Memo" or SRSetup."Use KID on Reminder") and
           not (SRSetup."KID Setup" in
                [SRSetup."KID Setup"::"Document Type+Document No.", SRSetup."KID Setup"::"Document No.+Document Type"])
        then
            Error(KIDSetupErr, SRSetup1."KID Setup", SRSetup2."KID Setup");
    end;

    procedure GetEInvoiceExportPaymentID(EInvoiceExportHeader: Record "E-Invoice Export Header"): Code[30]
    var
        GiroKID: Text[25];
        KIDError: Boolean;
    begin
        GenerateGiroKID(1, EInvoiceExportHeader."No.", EInvoiceExportHeader."Bill-to Customer No.", GiroKID, KIDError);
        if KIDError or (GiroKID = '') then
            exit(EInvoiceExportHeader."No.");
        exit(GiroKID);
    end;

    procedure GetEInvoicePEPPOLPaymentID(SalesHeader: Record "Sales Header"): Code[30]
    begin
        exit(GetEHFDocumentPaymentID(SalesHeader, 1));
    end;

    procedure GetEHFDocumentPaymentID(SalesHeader: Record "Sales Header"; DocumentType: Integer): Code[30]
    var
        GiroKID: Text[25];
        KIDError: Boolean;
    begin
        GenerateGiroKID(DocumentType, SalesHeader."No.", SalesHeader."Bill-to Customer No.", GiroKID, KIDError);
        if KIDError or (GiroKID = '') then
            exit(SalesHeader."No.");
        exit(GiroKID);
    end;

    procedure GetKundeID(var KundeTxt: Text; var KundeID: Text[25]; DocumentType: Integer; DocumentNo: Code[20]; CustomerNo: Code[20]);
    var
        KIDError: Boolean;
    begin
        KundeTxt := KundeIDTxt;
        GenerateGiroKID(DocumentType, DocumentNo, CustomerNo, KundeID, KIDError);
        if KundeID = '' then
            KundeTxt := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteGenJnlLine(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    var
        GenJnlLineRegRepCode: Record "Gen. Jnl. Line Reg. Rep. Code";
    begin
        GenJnlLineRegRepCode.SetRange("Journal Template Name", Rec."Journal Template Name");
        GenJnlLineRegRepCode.SetRange("Journal Batch Name", Rec."Journal Batch Name");
        GenJnlLineRegRepCode.SetRange("Line No.", Rec."Line No.");
        GenJnlLineRegRepCode.DeleteAll();
    end;

    procedure IsNorgeSEPACT(GenJournalLine: Record "Gen. Journal Line") Result: Boolean
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsNorgeSEPACT(GenJournalLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            if BankAccount.Get(GenJournalBatch."Bal. Account No.") then
                if BankExportImportSetup.Get(BankAccount."Payment Export Format") then
                    exit(BankExportImportSetup."Processing Codeunit ID" = CODEUNIT::"Norge SEPA CC-Export File");
        exit(false);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Suggest Vendor Payments", 'OnBeforeUpdateGnlJnlLineDimensionsFromVendorPaymentBuffer', '', false, false)]
    local procedure SuggestVendorPaymentUpdateRemittance(var GenJournalLine: Record "Gen. Journal Line"; TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary)
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Vendor.Get(TempVendorPaymentBuffer."Vendor No.");
        GenJournalLine.Validate("Remittance Account Code", Vendor."Remittance Account Code");
        if VendorLedgerEntry.Get(TempVendorPaymentBuffer."Vendor Ledg. Entry No.") then begin
            GenJournalLine.Validate("External Document No.", VendorLedgerEntry."External Document No.");
            GenJournalLine.Validate("Applies-to Ext. Doc. No.", VendorLedgerEntry."External Document No.");
            GenJournalLine.Validate(KID, VendorLedgerEntry.KID);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsNorgeSEPACT(GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exp. Pre-Mapping Gen. Jnl.", 'OnBeforeInsertPaymentExoprtData', '', false, false)]
    local procedure UpdatePaymentExportDataOnMappingGenJnl(var PaymentExportData: Record "Payment Export Data"; GenJournalLine: Record "Gen. Journal Line"; GeneralLedgerSetup: Record "General Ledger Setup")
    begin
        PaymentExportData.KID := GenJournalLine.KID;
    end;
}

