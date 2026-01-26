// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using System.Reflection;
using System.Utilities;

codeunit 11503 CHMgt
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'No valid ESR bank has been defined. You can define an ESR bank in three areas:\1. ESR bank from requestform\2. Payment type on customer or sales header\3. Main bank in ESR setup.';
        Text004: Label 'The reference number must have 27 characters. Please check the ESR setup.';
        CannotAssignReferenceNoMsg: Label 'The Reference No. field could not be filled automatically because more than one vendor ledger entry exist for the payment.';

    procedure PrepareEsr(SalesInvHeader: Record "Sales Invoice Header"; var ESRSetup: Record "ESR Setup"; var EsrType: Option Default,ESR,"ESR+"; var Adr: array[8] of Text[100]; var AmtTxt: Text[30]; var CurrencyCode: Code[10]; var DocType: Text[10]; var RefNo: Text[35]; var CodingLine: Text[100])
    var
        Amt: Decimal;
    begin
        Adr[1] := SalesInvHeader."Bill-to Name";
        Adr[2] := SalesInvHeader."Bill-to Contact";
        Adr[3] := SalesInvHeader."Bill-to Address";
        Adr[4] := SalesInvHeader."Bill-to Address 2";
        Adr[5] := SalesInvHeader."Bill-to Post Code" + ' ' + SalesInvHeader."Bill-to City";
        CompressArray(Adr);

        SalesInvHeader.CalcFields("Amount Including VAT");
        Amt := SalesInvHeader."Amount Including VAT";
        OnPrepareEsrOnAfterCalcAmt(SalesInvHeader, Amt);

        OnPrepareEsrOnBeforeCompressArray(SalesInvHeader, Adr);

        PrepareEsrConsolidate(
            ESRSetup, EsrType, AmtTxt, CurrencyCode, DocType, RefNo, CodingLine, SalesInvHeader."Currency Code",
            SalesInvHeader."Payment Method Code", SalesInvHeader."No.", Amt);
    end;


    procedure PrepareEsrConsolidate(var ESRSetup: Record "ESR Setup"; var EsrType: Option Default,ESR,"ESR+"; var AmtTxt: Text[30]; var CurrencyCode: Code[10]; var DocType: Text[10]; var RefNo: Text[35]; var CodingLine: Text[100]; CurrencyCode2: Code[10]; PaymentMethodCode: Code[10]; _No: Code[20]; Amt: Decimal)
    var
        GlSetup: Record "General Ledger Setup";
        BankMgt: Codeunit BankMgt;
        InvoiceNo: Text[8];
        CheckDigit: Text[2];
        AmtUnits: Decimal;
        AmtDecimals: Decimal;
        AmtUnitsTxt: Text[10];
        AmtDecimalsTxt: Text[20];
        OcrAmt: Text[20];
        OcrRefNo: Text[50];
        OcrAccNo: Code[20];
        OcrTypeESR: Text[2];
        OcrTypeEsrPlus: Text[3];
        ReqESRBankCode: Code[20];
    begin
        RefNo := '';
        AmtTxt := '';
        CodingLine := '';

        GlSetup.Get();

        if ESRSetup."Bank Code" <> '' then
            ReqESRBankCode := ESRSetup."Bank Code";
        Clear(ESRSetup);

        CurrencyCode := '';
        case CurrencyCode2 of
            '', GlSetup."LCY Code":
                begin
                    CurrencyCode := 'CHF';
                    DocType := '609';
                    OcrTypeESR := '01';
                    OcrTypeEsrPlus := '042';
                end;

            'EUR':
                begin
                    CurrencyCode := 'EUR';
                    DocType := '701';
                    OcrTypeESR := '21';
                    OcrTypeEsrPlus := '319';
                end;
        end;

        if CurrencyCode = '' then
            exit;

        if not ESRSetup.Get(ReqESRBankCode) then
            if PaymentMethodCode <> '' then begin
                ESRSetup.SetRange("ESR Payment Method Code", PaymentMethodCode);
                if not ESRSetup.FindFirst() then;
            end;

        if ESRSetup."Bank Code" = '' then begin
            ESRSetup.Reset();
            ESRSetup.SetRange("ESR Main Bank", true);
            if not ESRSetup.FindFirst() then
                Error(Text000);
        end;

        if EsrType = EsrType::Default then
            EsrType := ESRSetup."ESR System" + 1;

        // *** P R E P A R E   R E F   N O
        // 27 digits: 11 x BESR ID + 0000000 + 8 x InvNo + checkdigit
        InvoiceNo := CopyStr('00000000', 1, 8 - StrLen(_No)) + _No;
        RefNo := ESRSetup."BESR Customer ID" + '0000000' + InvoiceNo;
        if StrLen(RefNo) <> 26 then
            Error(Text004);

        CheckDigit := BankMgt.CalcCheckDigit(RefNo);
        RefNo := RefNo + CheckDigit;
        OcrRefNo := RefNo;

        // 5er blocks refno
        RefNo := CopyStr(RefNo, 1, 2) + ' ' + CopyStr(RefNo, 3, 5) + ' ' + CopyStr(RefNo, 8, 5) + ' ' +
          CopyStr(RefNo, 13, 5) + ' ' + CopyStr(RefNo, 18, 5) + ' ' + CopyStr(RefNo, 23, 5);

        if CurrencyCode = 'CHF' then
            Amt := Round(Amt, 0.05)
        else
            Amt := Round(Amt, 0.01);

        // Split units and decimals
        AmtUnits := Round(Amt, 1, '<');
        AmtDecimals := (Amt - AmtUnits) * 100;
        AmtUnitsTxt := Format(AmtUnits, 8, '<Integer>');
        AmtDecimalsTxt := ConvertStr(Format(AmtDecimals, 2, 2), ' ', '0');  // Trailing 0
        AmtTxt := AmtUnitsTxt + AmtDecimalsTxt;

        // Prepare OCR amt 12 digits + checkdigit: 0100000025803
        OcrAmt := OcrTypeESR + ConvertStr(AmtUnitsTxt, ' ', '0') + AmtDecimalsTxt;
        CheckDigit := BankMgt.CalcCheckDigit(OcrAmt);
        OcrAmt := OcrAmt + CheckDigit;

        // *** E S R   A C C O U N T   N O  - Expand and remove dashes
        OcrAccNo := BankMgt.CheckPostAccountNo(ESRSetup."ESR Account No.");
        OcrAccNo := DelChr(OcrAccNo, '=', '-');

        // *** C O D I N G   L I N E - for ESR/ESR+
        if EsrType = EsrType::ESR then
            CodingLine := OcrAmt + '>' + OcrRefNo + '+ ' + OcrAccNo + '>';

        if EsrType = EsrType::"ESR+" then begin
            CodingLine := '          ' + OcrTypeEsrPlus + '>' + OcrRefNo + '+ ' + OcrAccNo + '>';
            AmtTxt := '';
        end;
    end;

    procedure ReplaceXMLNamespaceCaption(var TempBlob: Codeunit "Temp Blob"; OldCaption: Text; NewCaption: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        OutStream: OutStream;
        XMLText: Text;
        XMLNamespaceStringTemplate: Text;
        XMLNamespaceString: Text;
        Position: Integer;
    begin
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        XMLText := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.CRLFSeparator());
        XMLNamespaceStringTemplate := '<Document xmlns="%1">';

        XMLNamespaceString := StrSubstNo(XMLNamespaceStringTemplate, OldCaption);
        Position := StrPos(XMLText, XMLNamespaceString);
        XMLText := DelStr(XMLText, Position, StrLen(XMLNamespaceString));

        XMLNamespaceString := StrSubstNo(XMLNamespaceStringTemplate, NewCaption);
        XMLText := InsStr(XMLText, XMLNamespaceString, Position);
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(XMLText);
    end;

    procedure IsSwissSEPACTExport(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        BalAccountNo: Code[20];
    begin
        if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            BalAccountNo := GenJournalBatch."Bal. Account No.";
        if BalAccountNo = '' then
            BalAccountNo := GenJournalLine."Bal. Account No.";

        if BankAccount.Get(BalAccountNo) then
            if BankExportImportSetup.Get(BankAccount."Payment Export Format") then
                exit(BankExportImportSetup."Processing Codeunit ID" = Codeunit::"Swiss SEPA CT-Export File");
        exit(false);
    end;

    procedure IsSwissSEPADDExport(DirectDebitCollectionNo: Integer): Boolean
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        if DirectDebitCollection.Get(DirectDebitCollectionNo) then
            if BankAccount.Get(DirectDebitCollection."To Bank Account No.") then
                if BankExportImportSetup.Get(BankAccount."SEPA Direct Debit Exp. Format") then
                    exit(BankExportImportSetup."Processing Codeunit ID" = CODEUNIT::"Swiss SEPA DD-Export File");
    end;

    procedure IsSwissSEPACTImport(BankAccountNo: Code[20]): Boolean
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        if BankAccount.Get(BankAccountNo) then
            if BankExportImportSetup.Get(BankAccount."Bank Statement Import Format") then
                exit(
                  BankExportImportSetup."Processing Codeunit ID" in
                  [CODEUNIT::"SEPA CAMT 053 Bank Rec. Lines", CODEUNIT::"SEPA CAMT 054 Bank Rec. Lines"]);
    end;

    procedure IsDomesticIBAN(IBAN: Code[50]): Boolean
    var
        DtaMgt: Codeunit DtaMgt;
    begin
        exit(CopyStr(DtaMgt.IBANDELCHR(IBAN), 1, 2) in ['CH', 'LI']);
    end;

    procedure IsDomesticCurrency(CurrencyCode: Code[10]): Boolean
    var
        DtaMgt: Codeunit DtaMgt;
    begin
        exit(DtaMgt.GetIsoCurrencyCode(CurrencyCode) in ['CHF', 'EUR']);
    end;

    procedure IsSEPACountry(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryCode) then
            exit(false);

        exit(
          CountryCode in
          ['BE', 'BG', 'DK', 'DE', 'EE', 'FI', 'FR', 'GI', 'GR', 'GB', 'IE', 'IS', 'IT', 'HR', 'LV', 'LI', 'LT', 'LU',
           'MT', 'MC', 'NL', 'NO', 'AT', 'PL', 'PT', 'RO', 'SE', 'CH', 'SK', 'SI', 'ES', 'CZ', 'HU', 'CY']);
    end;

    procedure IsESRFormat(RefNo: Text): Boolean
    var
        BankMgt: Codeunit BankMgt;
        CheckDigit: Text[1];
    begin
        if DelChr(RefNo, '=', '1234567890') <> '' then
            exit(false);

        if StrLen(RefNo) <> 27 then
            exit(false);

        CheckDigit := CopyStr(Format(RefNo[StrLen(RefNo)]), 1, MaxStrLen(CheckDigit));
        if BankMgt.CalcCheckDigit(PadStr(RefNo, StrLen(RefNo) - 1)) <> CheckDigit then
            exit(false);

        exit(true);
    end;

    local procedure CopyReferenceFromVLEToGenJournalLine(VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        if VendorLedgerEntry."Reference No." = '' then
            exit;

        VendorBankAccount.Get(VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Recipient Bank Account");
        if (VendorBankAccount."Payment Form" = VendorBankAccount."Payment Form"::ESR) and (VendorBankAccount."ESR Type" = VendorBankAccount."ESR Type"::"5/15") then begin
            GenJournalLine."Reference No." := CopyStr(VendorLedgerEntry."Reference No.", 1, 15);
            if StrLen(GenJournalLine."Reference No.") > 15 then
                GenJournalLine.Checksum := CopyStr(VendorLedgerEntry."Reference No.", 17, 2);
        end else
            GenJournalLine."Reference No." := VendorLedgerEntry."Reference No.";

        GenJournalLine."Recipient Bank Account" := VendorLedgerEntry."Recipient Bank Account";
    end;

    local procedure FindFirstVendLedgEntryWithAppliesToID(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AccNo: Code[20]; AppliesToID: Code[50]): Boolean
    begin
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open);
        VendorLedgerEntry.SetRange("Vendor No.", AccNo);
        VendorLedgerEntry.SetRange("Applies-to ID", AppliesToID);
        VendorLedgerEntry.SetRange(Open, true);
        exit(VendorLedgerEntry.FindSet());
    end;

    local procedure FindFirstVendLedgEntryWithAppliesToDocNo(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AccNo: Code[20]; AppliestoDocType: Enum "Gen. Journal Document Type"; AppliestoDocNo: Code[20]): Boolean
    begin
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetCurrentKey("Document No.");
        VendorLedgerEntry.SetRange("Document No.", AppliestoDocNo);
        VendorLedgerEntry.SetRange("Document Type", AppliestoDocType);
        VendorLedgerEntry.SetRange("Vendor No.", AccNo);
        VendorLedgerEntry.SetRange(Open, true);
        exit(VendorLedgerEntry.FindFirst());
    end;

    local procedure SendReferenceNoCollisionNotification()
    var
        ReferenceNoNotificaiton: Notification;
    begin
        ReferenceNoNotificaiton.Id := GetReferenceNoCollisionNotificationId();
        ReferenceNoNotificaiton.Recall();

        ReferenceNoNotificaiton.Message := CannotAssignReferenceNoMsg;
        ReferenceNoNotificaiton.Scope := NOTIFICATIONSCOPE::LocalScope;
        ReferenceNoNotificaiton.Send();
    end;

    local procedure GetReferenceNoCollisionNotificationId(): Guid
    begin
        exit('957D62D7-3D00-4C8F-A3B0-D14DBC9EC4FD');
    end;

    procedure NoOfPaymentsForBatchBooking(): Integer
    begin
        exit(50);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Suggest Vendor Payments", 'OnBeforeUpdateGnlJnlLineDimensionsFromVendorPaymentBuffer', '', false, false)]
    local procedure SuggestVendorPaymentFromBufferUpdatePaymentLine(var GenJournalLine: Record "Gen. Journal Line"; TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary)
    begin
        // NewDescription = Description + ', ' + ExternalDocNo, where Description is truncated to fit full ExternalDocNo value
        if TempVendorPaymentBuffer."Applies-to Ext. Doc. No." <> '' then
            GenJournalLine.Description :=
              Format(
                CopyStr(
                  GenJournalLine.Description,
                  1, MaxStrLen(GenJournalLine.Description) - StrLen(TempVendorPaymentBuffer."Applies-to Ext. Doc. No.") - 2) +
                ', ' + TempVendorPaymentBuffer."Applies-to Ext. Doc. No.",
                -MaxStrLen(GenJournalLine.Description));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Payment Buffer", 'OnAfterCopyFieldsFromVendorLedgerEntry', '', false, false)]
    local procedure HandleOnAfterCopyFieldsFromVendorLedgerEntryFromBuffer(VendorLedgerEntrySource: Record "Vendor Ledger Entry"; var VendorPaymentBufferTarget: Record "Vendor Payment Buffer")
    begin
        VendorPaymentBufferTarget."Reference No." := VendorLedgerEntrySource."Reference No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Payment Buffer", 'OnAfterCopyFieldsToGenJournalLine', '', false, false)]
    local procedure HandleOnAfterCopyFieldsToGenJournalLineFromBuffer(VendorPaymentBufferSource: Record "Vendor Payment Buffer"; var GenJournalLineTarget: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VendorPaymentBufferSource."Vendor Ledg. Entry No." <> 0 then begin
            GenJournalLineTarget."Reference No." := VendorPaymentBufferSource."Reference No.";
            VendorLedgerEntry.Get(VendorPaymentBufferSource."Vendor Ledg. Entry No.");
            if VendorLedgerEntry."Recipient Bank Account" <> '' then
                GenJournalLineTarget.Validate("Recipient Bank Account", VendorLedgerEntry."Recipient Bank Account");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterSetJournalLineFieldsFromApplication', '', false, false)]
    local procedure HandleOnAfterSetJournalLineFieldsFromApplication(var GenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; xGenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if AccType = AccType::Vendor then begin
            GenJournalLine."Reference No." := '';
            if GenJournalLine."Applies-to ID" <> '' then begin
                if FindFirstVendLedgEntryWithAppliesToID(VendorLedgerEntry, AccNo, GenJournalLine."Applies-to ID") then
                    if VendorLedgerEntry.Next() = 0 then
                        CopyReferenceFromVLEToGenJournalLine(VendorLedgerEntry, GenJournalLine)
                    else
                        SendReferenceNoCollisionNotification();
            end else
                if GenJournalLine."Applies-to Doc. No." <> '' then
                    if FindFirstVendLedgEntryWithAppliesToDocNo(VendorLedgerEntry, AccNo, GenJournalLine."Applies-to Doc. Type", GenJournalLine."Applies-to Doc. No.") then
                        CopyReferenceFromVLEToGenJournalLine(VendorLedgerEntry, GenJournalLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Totals", 'OnAfterSalesLineSetFilters', '', false, false)]
    local procedure HandleOnAfterSalesLineSetFilters(var TotalSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line")
    begin
        TotalSalesLine.SetFilter("Quote Variant", '<>%1', TotalSalesLine."Quote Variant"::Variant);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Totals", 'OnAfterSalesCheckIfDocumentChanged', '', false, false)]
    local procedure HandleOnAfterSalesCheckIfDocumentChanged(SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var TotalsUpToDate: Boolean)
    begin
        if SalesLine."Quote Variant" <> xSalesLine."Quote Variant" then
            TotalsUpToDate := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Totals", 'OnCalculateSalesSubPageTotalsOnAfterSetFilters', '', false, false)]
    local procedure HandleOnCalculateSalesSubPageTotalsOnAfterSetFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetFilter("Quote Variant", '<>%1', SalesLine."Quote Variant"::Variant);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareEsrOnAfterCalcAmt(var SalesInvoiceHeader: Record "Sales Invoice Header"; var Amt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareEsrOnBeforeCompressArray(var SalesInvoiceHeader: Record "Sales Invoice Header"; var Adr: array[8] of Text[100])
    begin
    end;

}