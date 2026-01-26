// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

codeunit 3010541 DtaMgt
{
    Permissions = TableData "Vendor Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        Text000Err: Label 'The length of the Coding Line is not correct. It has %1 digits instead:\\52 for ESR 9/27 \42 for ESR+ 9/27 \41 for ESR 9/16 \31 for ESR+ 9/16 \39 for ESR 5/15 \22 for ESR+ 5/15 \38 for Pmt. Bank \10 for Pmt. Post.';
        Text009Err: Label 'No vendor bank was found for payment type %1 and vendor %2. \Select the vendor no. on the general ledger line and read the document again. \%3 will try to find a bank based on the coding line.', Comment = '%3 - product name';
        Text012Qst: Label 'There is no vendor bank account with payment type %2 for vendor %1. Do you want to create it?';
        Text013Err: Label 'There is no vendor bank account with payment type %2 for vendor %1.';
        Text015Qst: Label 'Bank %2 has been created for vendor %1.\\Do you want to see the bank card to check the entry or to add a balance account, bank account number or position of invoice number?';
        Text015Msg: Label 'There are multiple vendor banks with payment type %1 and account %2.\\Select an entry from the list.';
        Text020Err: Label 'Vendor bank "%1" for vendor %2 no found.';
        Text021Err: Label 'Reference numbers are only permitted for ESR and ESR+. \For vendor %1, bank code %2 with payment type %3 is defined.';
        Text023Err: Label 'The check digit is only used for ESR type 5/15.';
        Text024Err: Label 'Reference numbers are only permitted for ESR and ESR+. Vendor %1 has bankcode %2 with payment type %3.';
        Text026Err: Label 'The reference number can contain max. %1 digits plus spaces.';
        Text027Qst: Label 'Expand the reference number to %1 digits?';
        Text028Err: Label 'The reference number must have one of the following formats:\\With spaces: 71010 08830 11434 \Without spaces: 710100883011434 \Without leading zeros: 30123455 \\Leading zeros can be added automatically.';
        Text036Err: Label 'The reference number must have one of the following formats:\\With spaces: 90 00070 10034 18240 00083 30411 \Without spaces: 9000701003418240008330411 \Without leading zeros: 10 35542 51050 21204 02955 \\ Leading zeros can be added automatically. \Spaces will be removed after correct entry.';
        Text040Err: Label 'The check digit of the reference no. is invalid.';
        Text043Err: Label 'The reference number must have one of the following formats:\With spaces: 3 13947 14300 09018 \Without spaces: 3139471430009018 \Without leading zeros: 89127 \Leading zeros can be added automatically. \Spaces will be removed after correct entry.';
        Text046Err: Label 'Vendor bank %1 in Vendor %2 is not defined.';
        Text047Err: Label 'The reference number may only be modified for payment type ESR and ESR+.';
        Text048Err: Label 'The reference number may only be modified for ESR type 9/16 and 9/27.';
        Text058Err: Label 'The check digit of coding line %1 must be %2.';
        Text070Err: Label 'The check digit of the amount on the coding line is not correct.';
        Text071Err: Label 'For vendor %1 and document %2, a reference number is defined. \The document type must be "Invoice".';
        Text073Err: Label 'The vendor bank %1 for vendor %2 and document %3 is not defined.';
        Text074Err: Label 'The vendor bank %1 for vendor %2 and document %3 %4 has payment type %5.\Invoices with payment type %5 must have a reference no. before posting.', Comment = 'Parameter 1 - bank code, 2 - vendor number, 3 -  document type ( ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund), 4 - document number, 5 - payment form.';
        Text076Err: Label 'Vendor bank %1 for vendor %2 not found.';
        Text077Err: Label '%1 %2 cannot be posted, because the reference number is missing. \The selected vendor bank %3 had payment type %4.', Comment = 'Parameter 1 - document type ( ), 2 - document number, 3 - bank code, 4 - payment form.';
        Text079Err: Label 'Invoice amount in document %1 based on the sum of purchase lines of %2 does not match the ESR amount %3 in the purchase header.\\You can modify quantity, prices order discount on the purchase lines or add a Rounding Line. Check the result in the statistics window of the invoice and order.';
        Text094Err: Label 'No DTA bank of type EZAG is defined.';
        Text100Qst: Label 'Do you want to modify the document number on all lines from %1 to %2?';
        Text101Qst: Label 'Do you also want to modify the exrate for the other %1 lines with currency %2?';
        Text110Err: Label 'You have entered a EUR/CHF ESR, but the expected currency is %1.';
        Text111Err: Label 'You have entered a EUR ESR, but the expected currency is %1.';
        Text112Err: Label 'You have entered a CHF ESR, but the expected currency is %1.';
        Text114Err: Label 'The ISO code %1 of currency %2 is invalid. It must have 3 characters.';
        Text115Err: Label 'Payment type %1 is only allowed in CHF/EUR. Vendor %2, Amount %3.';
        Text116Err: Label 'Payment type %1 is not allowed for DTA.\Vendor: %2, Bank Code: %3.';
        VendBank: Record "Vendor Bank Account";
        VB2: Record "Vendor Bank Account";
        DtaSetup: Record "DTA Setup";
        GlLine: Record "Gen. Journal Line";
        GlSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        BankMgt: Codeunit BankMgt;
        RefNo: Text[30];
        ChkDig: Text[10];
        EsrAmt: Decimal;
        Text117Err: Label 'Payment type %1 is only allowed in CHF. Vendor %2, Amount %3.';
        DetailInfoMsg: Label '\%1: %2.', Locked = true;

    [Scope('OnPrem')]
    procedure CheckSetup()
    begin
        DtaSetup.SetRange("DTA/EZAG", DtaSetup."DTA/EZAG"::DTA);
        if DtaSetup.FindSet() then
            repeat
                DtaSetup.TestField("DTA Customer ID");
                DtaSetup.TestField("DTA Sender ID");
                DtaSetup.TestField("DTA Sender Clearing");
                DtaSetup.TestField("DTA Debit Acc. No.");
                DtaSetup.TestField("DTA Sender Name");
                DtaSetup.TestField("DTA Sender City");
            until DtaSetup.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessGlLine(var GenJnlLine: Record "Gen. Journal Line"; CodingLine: Text[70])
    var
        CurrExch: Record "Currency Exchange Rate";
        ESRTransactionCode: Integer;
    begin
        if CodingLine = '' then
            exit;
        // CHeck Pmt Method, Amt, RefNo, CheckDig, Clear. Return in VendBank2
        ProcessCodingLine(CodingLine);
        // Get Vendor Bank according to ESR/PostAcc/Clearing. Get Vendor No
        // VB2 Aux. Record für Para. Transfer. Fetched Bank is in Rec VB
        case VB2."Payment Form" of
            VB2."Payment Form"::ESR, VB2."Payment Form"::"ESR+":
                GetVendorBank(VB2, VB2."ESR Account No.", GenJnlLine."Account No.");
            VB2."Payment Form"::"Post Payment Domestic":
                GetVendorBank(VB2, VB2."Giro Account No.", GenJnlLine."Account No.");
            VB2."Payment Form"::"Bank Payment Domestic":
                GetVendorBank(VB2, VB2."Clearing No.", GenJnlLine."Account No.");
        end;
        // Fill in GLL according to coding line and vendor bank
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
        GenJnlLine.Validate("Account No.", VendBank."Vendor No.");
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Invoice);
        GenJnlLine.Validate("Recipient Bank Account", VendBank.Code);
        GenJnlLine.Validate("Reference No.", RefNo);
        // CHeck ref. no. get ext. doc. no
        GenJnlLine.Validate(Checksum, ChkDig);
        GenJnlLine.Validate(Amount, -EsrAmt);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", VendBank."Balance Account No.");

        if (StrLen(CodingLine) > 12) and not (StrLen(CodingLine) in [22, 39]) then begin
            Evaluate(ESRTransactionCode, CopyStr(DelChr(CodingLine, '=', '<'), 1, 2));
            if ESRTransactionCode > 20 then begin
                GenJnlLine."Currency Code" := 'EUR';
                GenJnlLine."Currency Factor" := CurrExch.ExchangeRate(GenJnlLine."Posting Date", GenJnlLine."Currency Code");
                GenJnlLine.Validate(Amount);
            end;
            CheckEsrCurrency(GenJnlLine."Currency Code", CodingLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure ProcessPurchHeader(var PurchHeader: Record "Purchase Header"; CodingLine: Text[70])
    var
        CurrExch: Record "Currency Exchange Rate";
        ESRTransactionCode: Integer;
    begin
        if CodingLine = '' then
            exit;

        ProcessCodingLine(CodingLine);
        // Get Vendor Bank
        case VB2."Payment Form" of
            VB2."Payment Form"::ESR, VB2."Payment Form"::"ESR+":
                GetVendorBank(VB2, VB2."ESR Account No.", PurchHeader."Pay-to Vendor No.");
            VB2."Payment Form"::"Post Payment Domestic":
                GetVendorBank(VB2, VB2."Giro Account No.", PurchHeader."Pay-to Vendor No.");
            VB2."Payment Form"::"Bank Payment Domestic":
                GetVendorBank(VB2, VB2."Clearing No.", PurchHeader."Pay-to Vendor No.");
        end;
        // Fill in purch header based on codingline and vendor bank
        if PurchHeader."Buy-from Vendor No." = '' then begin
            PurchHeader.Validate("Buy-from Vendor No.", VendBank."Vendor No.");
            Commit();
        end;

        PurchHeader.Validate("Bank Code", VendBank.Code);
        PurchHeader.Validate("Reference No.", RefNo);
        PurchHeader.Validate(Checksum, ChkDig);
        PurchHeader.Validate("ESR Amount", EsrAmt);

        if (StrLen(CodingLine) > 12) and not (StrLen(CodingLine) in [22, 39]) then begin
            Evaluate(ESRTransactionCode, CopyStr(DelChr(CodingLine, '=', '<'), 1, 2));
            if ESRTransactionCode > 20 then begin
                PurchHeader."Currency Code" := 'EUR';
                PurchHeader."Currency Factor" := CurrExch.ExchangeRate(PurchHeader."Posting Date", PurchHeader."Currency Code");
                PurchHeader.CalcFields(Amount);
                PurchHeader.Validate(Amount);
            end;
            CheckEsrCurrency(PurchHeader."Currency Code", CodingLine);
        end;
    end;

    local procedure ProcessCodingLine(var CodingLine: Text[70])
    begin
        // Call from ProcessGlLine and ProcessPurchHeader
        // VB2: Aux. record for pmt type and return of account

        Clear(VB2);
        RefNo := '';
        ChkDig := '';
        EsrAmt := 0;

        CodingLine := DelChr(CodingLine);  // Delete spaces

        // Payment and ESR-Type according to Length
        case StrLen(CodingLine) of
            52:
                begin  // ESR 9/27
                    VB2."ESR Type" := VB2."ESR Type"::"9/27";
                    VB2."Payment Form" := VB2."Payment Form"::ESR;
                    RefNo := CopyStr(CodingLine, 15, 27);
                    VB2."ESR Account No." := CopyStr(CodingLine, 43, 9);
                    CheckAmountChkDig := CopyStr(CodingLine, 1, 13);
                    EsrAmt := AmountInDecimal(CopyStr(CodingLine, 3, 10));
                end;
            42:
                begin  // ESR+ 9/27
                    VB2."ESR Type" := VB2."ESR Type"::"9/27";
                    VB2."Payment Form" := VB2."Payment Form"::"ESR+";
                    RefNo := CopyStr(CodingLine, 5, 27);
                    VB2."ESR Account No." := CopyStr(CodingLine, 33, 9);
                end;
            41:
                begin  // ESR 9/16
                    VB2."ESR Type" := VB2."ESR Type"::"9/16";
                    VB2."Payment Form" := VB2."Payment Form"::ESR;
                    RefNo := CopyStr(CodingLine, 15, 16);
                    VB2."ESR Account No." := CopyStr(CodingLine, 32, 9);
                    CheckAmountChkDig := CopyStr(CodingLine, 1, 13);
                    EsrAmt := AmountInDecimal(CopyStr(CodingLine, 3, 10));
                end;
            31:
                begin  // ESR+ 9/16
                    VB2."ESR Type" := VB2."ESR Type"::"9/16";
                    VB2."Payment Form" := VB2."Payment Form"::"ESR+";
                    RefNo := CopyStr(CodingLine, 5, 16);
                    VB2."ESR Account No." := CopyStr(CodingLine, 22, 9);
                end;
            39:
                begin  // ESR 5/15
                    VB2."ESR Type" := VB2."ESR Type"::"5/15";
                    VB2."Payment Form" := VB2."Payment Form"::ESR;
                    RefNo := CopyStr(CodingLine, 18, 15);
                    ChkDig := CopyStr(CodingLine, 2, 2);
                    VB2."ESR Account No." := CopyStr(CodingLine, 34, 5);
                    EsrAmt := AmountInDecimal(CopyStr(CodingLine, 8, 9));
                end;
            22:
                begin  // ESR+ 5/15
                    VB2."ESR Type" := VB2."ESR Type"::"5/15";
                    VB2."Payment Form" := VB2."Payment Form"::"ESR+";
                    RefNo := CopyStr(CodingLine, 1, 15);
                    VB2."ESR Account No." := CopyStr(CodingLine, 17, 5);
                end;
            38:
                begin  // EZ Bank
                    VB2."ESR Type" := VB2."ESR Type"::" ";
                    VB2."Payment Form" := VB2."Payment Form"::"Bank Payment Domestic";
                    VB2."Clearing No." := DelChr(CopyStr(CodingLine, 31, 5), '<', '0');
                end;
            10:
                begin  // EZ Post
                    VB2."ESR Type" := VB2."ESR Type"::" ";
                    VB2."Payment Form" := VB2."Payment Form"::"Post Payment Domestic";
                    VB2."Giro Account No." := CopyStr(CodingLine, 1, 9);
                end;
            else
                Error(Text000Err, StrLen(CodingLine));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVendorBank(VendorBankAccount: Record "Vendor Bank Account"; AccNo: Text[20]; VendorNo: Code[20])
    var
        VendorBankCode: Code[20];
    begin
        // Get Vendor and Bankcode based on ESR Account ID
        Clear(VendBank);

        if VendorBankAccount."Payment Form" >= VendorBankAccount."Payment Form"::"Cash Outpayment Order Domestic" then
            exit;

        if VendorBankAccount."Payment Form" <> VendorBankAccount."Payment Form"::"Bank Payment Domestic" then
            AccNo := PostAccountInsertDash(AccNo);

        if VendorNo <> '' then
            VendBank.SetRange("Vendor No.", VendorNo) // from GlLine
        else
            VendBank.SetCurrentKey("ESR Account No.");

        VendBank.SetRange("Payment Form", VendorBankAccount."Payment Form");  // from Coding Line
        case VendorBankAccount."Payment Form" of
            VendorBankAccount."Payment Form"::ESR, VendorBankAccount."Payment Form"::"ESR+":
                VendBank.SetRange("ESR Account No.", AccNo);
            VendorBankAccount."Payment Form"::"Post Payment Domestic":
                VendBank.SetRange("Giro Account No.", AccNo);
            VendorBankAccount."Payment Form"::"Bank Payment Domestic":
                VendBank.SetRange("Clearing No.", AccNo);
        end;

        case VendBank.Count of
            1:
                VendBank.FindFirst();  // Only one entry with this account
            0:
                begin  // No bank and no vendor No.
                    if VendorNo = '' then
                        Error(Text009Err, VendorBankAccount."Payment Form", AccNo, PRODUCTNAME.Full());

                    VendorBankCode := Format(VendorBankAccount."Payment Form", -MaxStrLen(VendBank.Code));
                    if not Confirm(Text012Qst, true, VendorNo, VendorBankCode) then
                        exit;

                    Clear(VendBank);
                    VendBank."Vendor No." := VendorNo;
                    VendBank.Code := VendorBankCode;
                    VendBank."Payment Form" := VendorBankAccount."Payment Form";
                    VendBank."ESR Type" := VendorBankAccount."ESR Type";
                    if VB2."Giro Account No." <> '' then
                        VendBank.Validate("Giro Account No.", PostAccountInsertDash(VendorBankAccount."Giro Account No."));
                    if VB2."ESR Account No." <> '' then
                        VendBank.Validate("ESR Account No.", PostAccountInsertDash(VendorBankAccount."ESR Account No."));
                    if VB2."Clearing No." <> '' then
                        VendBank.Validate("Clearing No.", VendorBankAccount."Clearing No.");
                    VendBank.Insert();

                    if Confirm(Text015Qst, true, VendorNo, VendorBankCode) then begin
                        Commit();
                        if PAGE.RunModal(PAGE::"Vendor Bank Account Card", VendBank) = ACTION::LookupOK then;
                    end;
                end
            else begin  // select from several banks with identical account
                Message(Text015Msg, VendorBankAccount."Payment Form", AccNo);
                if PAGE.RunModal(PAGE::"Vendor Bank Account List", VendBank) = ACTION::LookupOK then;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ProcessGlRefNo(var GLL: Record "Gen. Journal Line")
    var
        NewRefNo: Text[35];
    begin
        if GLL."Reference No." = '' then
            exit;

        if not VendBank.Get(GLL."Account No.", GLL."Recipient Bank Account") then
            Error(Text020Err, GLL."Recipient Bank Account", GLL."Account No.");
        // Ref. No only for ESR and ESR+
        if VendBank."Payment Form" > 1 then
            Error(Text021Err, GLL."Account No.", GLL."Recipient Bank Account", VendBank."Payment Form");
        // CHeck Digit only for ESR 5/15
        if (GLL.Checksum <> '') and
           ((VendBank."Payment Form" <> VendBank."Payment Form"::ESR) or (VendBank."ESR Type" <> VendBank."ESR Type"::"5/15"))
        then
            Error(Text023Err);

        NewRefNo := CheckRefNo(GLL."Reference No.", GLL.Checksum, GLL.Amount);

        if VendBank."Invoice No. Startposition" > 0 then
            GLL."External Document No." := CopyStr(NewRefNo, VendBank."Invoice No. Startposition", VendBank."Invoice No. Length");

        GLL."Reference No." := NewRefNo;
    end;

    [Scope('OnPrem')]
    procedure PurchHeadRefNoProcess(var PurchHead: Record "Purchase Header")
    var
        NewRefNo: Text[35];
    begin
        if PurchHead."Reference No." = '' then
            exit;

        if not VendBank.Get(PurchHead."Pay-to Vendor No.", PurchHead."Bank Code") then
            Error(Text020Err, PurchHead."Bank Code", PurchHead."Pay-to Vendor No.");
        // Ref. No only for ESR and ESR+
        if VendBank."Payment Form" > 1 then
            Error(Text024Err, PurchHead."Pay-to Vendor No.", PurchHead."Bank Code", VendBank."Payment Form");
        // CHeck Digit only for ESR 5/15
        if (PurchHead.Checksum <> '') and
           ((VendBank."Payment Form" <> VendBank."Payment Form"::ESR) or (VendBank."ESR Type" <> VendBank."ESR Type"::"5/15"))
        then
            Error(Text023Err);

        NewRefNo := CheckRefNo(PurchHead."Reference No.", PurchHead.Checksum, PurchHead."ESR Amount");

        if VendBank."Invoice No. Startposition" > 0 then
            PurchHead."Vendor Invoice No." := CopyStr(NewRefNo, VendBank."Invoice No. Startposition", VendBank."Invoice No. Length");

        PurchHead."Reference No." := NewRefNo;
    end;

    [Scope('OnPrem')]
    procedure CheckRefNo(RefNo: Text[35]; ChkDig: Text[2]; Amt: Decimal) NewRefNo: Text[35]
    var
        Teststring: Text[30];
    begin
        if RefNo = '' then
            exit;

        // Test 15-Char Ref. Number
        if VendBank."ESR Type" = VendBank."ESR Type"::"5/15" then begin
            RefNo := DelChr(RefNo);
            if StrLen(RefNo) > 15 then
                Error(Text026Err, 15);

            if StrLen(RefNo) < 15 then
                if Confirm(Text027Qst, true, 15) then
                    RefNo := CopyStr('0000000000000000', 1, 15 - StrLen(RefNo)) + RefNo;

            if StrLen(RefNo) <> 15 then
                Error(Text028Err);

            if (Amt <> 0) and (ChkDig <> '') then
                Modulo11(RefNo, ChkDig, Amt);
        end;

        // CHeck 27-Digit Ref. No.
        if VendBank."ESR Type" = VendBank."ESR Type"::"9/27" then begin
            RefNo := DelChr(RefNo);
            if StrLen(RefNo) > 27 then
                Error(Text026Err, 27);

            if StrLen(RefNo) < 27 then
                if Confirm(Text027Qst, true, 27) then
                    RefNo := CopyStr('000000000000000000000000000', 1, 27 - StrLen(RefNo)) + RefNo;

            if StrLen(RefNo) <> 27 then
                Error(Text036Err);

            ChkDig := CopyStr(RefNo, StrLen(RefNo), 1);  // Get CheckDig
            Teststring := CopyStr(RefNo, 1, StrLen(RefNo) - 1);  // Without CheckDig

            if ChkDig <> BankMgt.CalcCheckDigit(Teststring) then
                Error(Text040Err);
        end;

        // CHeck 27-Digit Ref. No.
        if VendBank."ESR Type" = VendBank."ESR Type"::"9/16" then begin
            RefNo := DelChr(RefNo);
            if StrLen(RefNo) > 16 then
                Error(Text026Err, 16);

            if StrLen(RefNo) < 16 then
                if Confirm(Text027Qst, true, 16) then
                    RefNo := CopyStr('0000000000000000', 1, 16 - StrLen(RefNo)) + RefNo;

            if StrLen(RefNo) <> 16 then
                Error(Text043Err);

            ChkDig := CopyStr(RefNo, StrLen(RefNo), 1);  // Get CheckDig
            Teststring := CopyStr(RefNo, 1, StrLen(RefNo) - 1);  // Without CheckDig

            if ChkDig <> BankMgt.CalcCheckDigit(Teststring) then
                Error(Text040Err);
        end;

        NewRefNo := RefNo; // Return modified Ref. No.
    end;

    [Scope('OnPrem')]
    procedure VendLedgEntriesCheckRefNo(VenLedgEnt: Record "Vendor Ledger Entry")
    var
        ChkDig: Code[1];
        Teststring: Code[30];
    begin
        // CHeck corrected 16 or 27 digit ref. no in vendor ledger entries
        if not VendBank.Get(VenLedgEnt."Vendor No.", VenLedgEnt."Recipient Bank Account") then
            Error(Text046Err, VenLedgEnt."Recipient Bank Account", VenLedgEnt."Vendor No.");

        if VendBank."Payment Form" > 1 then  // not ESR, ESR+
            VendLedgEntriesCheckRefError(VenLedgEnt, Text047Err);

        if VendBank."ESR Type" < 2 then  // empty or 5/15
            VendLedgEntriesCheckRefError(VenLedgEnt, Text048Err);

        ChkDig := CopyStr(VenLedgEnt."Reference No.", StrLen(VenLedgEnt."Reference No."), 1);  // Get CheckDig
        Teststring := CopyStr(VenLedgEnt."Reference No.", 1, StrLen(VenLedgEnt."Reference No.") - 1);  // without CheckDig
        if ChkDig <> BankMgt.CalcCheckDigit(Teststring) then
            Error(Text040Err);
    end;

    local procedure VendLedgEntriesCheckRefError(VendorLedgerEntry: Record "Vendor Ledger Entry"; TextErr: Text)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        Error(
          StrSubstNo('%1%2%3%4%5',
            TextErr,
            StrSubstNo(DetailInfoMsg, Vendor.TableCaption(), VendorLedgerEntry."Vendor No."),
            StrSubstNo(DetailInfoMsg, VendorBankAccount.TableCaption(), VendorLedgerEntry."Recipient Bank Account"),
            StrSubstNo(DetailInfoMsg, VendorLedgerEntry.FieldCaption("Document Type"), VendorLedgerEntry."Document Type"),
            StrSubstNo(DetailInfoMsg, VendorLedgerEntry.FieldCaption("Document No."), VendorLedgerEntry."Document No.")));
    end;

    [Scope('OnPrem')]
    procedure PostAccountInsertDash(AccWithoutDash: Text[20]): Text[20]
    begin
        if StrLen(AccWithoutDash) = 9 then
            exit(
              CopyStr(AccWithoutDash, 1, 2) + '-' +
              CopyStr(AccWithoutDash, 3, 6) + '-' +
              CopyStr(AccWithoutDash, 9, 1));
        exit(AccWithoutDash);  // 5/15
    end;

    [Scope('OnPrem')]
    procedure Modulo11(RefNo: Text[35]; ChkDig: Text[2]; Amt: Decimal)
    var
        Mod11Input: Text[55];
        Mod11PZ: Text[2];
        AmtTxt: Text[15];
    begin
        // From Amt always, if not ESR+
        // Of Check11, if Ref and Amount are completed
        // Of Ref, if Chekc11 and Amount are completed

        AmtTxt := Format(Amt * 100, 0, '<Integer>');  // Amount on 9 digits, leading 0
        AmtTxt := CopyStr('000000000', 1, 9 - StrLen(AmtTxt)) + AmtTxt;

        Mod11Input := '0001' + AmtTxt + RefNo + VendBank."ESR Account No.";
        Mod11PZ := Format(StrCheckSum(Mod11Input, '432765432765432765432765432765432', 11));

        if StrLen(Mod11PZ) = 1 then
            Mod11PZ := '0' + Mod11PZ;  // leading 0
        if Mod11PZ <> ChkDig then
            Error(Text058Err, Mod11Input, Mod11PZ);
    end;

    [Scope('OnPrem')]
    procedure CheckAmountChkDig(AmtString: Text[20])
    var
        ChkDig: Text[2];
    begin
        ChkDig := CopyStr(AmtString, 13, 1);
        AmtString := CopyStr(AmtString, 1, 12);
        if ChkDig <> BankMgt.CalcCheckDigit(AmtString) then
            Error(Text070Err);
    end;

    [Scope('OnPrem')]
    procedure AmountInDecimal(AmtString: Text[20]) AmtDec: Decimal
    begin
        Evaluate(AmtDec, AmtString);
        AmtDec := AmtDec / 100;
    end;

    [Scope('OnPrem')]
    procedure CheckVenorPost(GLL: Record "Gen. Journal Line")
    begin
        // Ref No found when ESR Invoice posted?
        // Reset Wait Flag (for rest payment)
        ReleaseVendorLedgerEntries(GLL);

        if (GLL."Account Type" = GLL."Account Type"::Vendor) and
           (GLL."Reference No." <> '') and
           (GLL."Document Type" <> GLL."Document Type"::Invoice) and
           (GLL."Applies-to Doc. No." = '') and (GLL."Applies-to ID" = '')
        then
            Error(Text071Err, GLL."Account No.", GLL."Document No.");

        if (GLL."Account Type" = GLL."Account Type"::Vendor) and
           (GLL."Document Type" = GLL."Document Type"::Invoice) and (GLL."Recipient Bank Account" <> '')
        then begin
            if not VendBank.Get(GLL."Account No.", GLL."Recipient Bank Account") then
                Error(Text073Err, GLL."Recipient Bank Account", GLL."Account No.", GLL."Document No.");

            if (VendBank."Payment Form" in [VendBank."Payment Form"::ESR, VendBank."Payment Form"::"ESR+"]) and
               (GLL."Reference No." = '')
            then
                Error(Text074Err, GLL."Recipient Bank Account", GLL."Account No.", GLL."Document Type", GLL."Document No.", VendBank."Payment Form");
        end;
    end;

    [Scope('OnPrem')]
    procedure TransferVendorGlLine(var GLL: Record "Gen. Journal Line")
    var
        VendBank: Record "Vendor Bank Account";
        Vendor: Record Vendor;
    begin
        // Transfer Vendor to Table 81, for Vendor Invoice
        if GLL."Document Type" <> GLL."Document Type"::Invoice then
            exit;

        Vendor.Get(GLL."Account No.");
        if GLL."Recipient Bank Account" = '' then  // if not filled in yet
            GLL."Recipient Bank Account" := Vendor."Preferred Bank Account Code";

        if VendBank.Get(GLL."Account No.", GLL."Recipient Bank Account") then
            GLL.Validate("Bal. Account No.", VendBank."Balance Account No.");
    end;

    [Scope('OnPrem')]
    procedure TransferPurchHeadGLL(var PurchHead: Record "Purchase Header"; var GLL: Record "Gen. Journal Line")
    begin
        // Transfer of PurchHead in GlLine in C90. ESR Info Transfer to GlLine
        if not PurchHead.Invoice then
            exit;

        if not (PurchHead."Document Type" in [PurchHead."Document Type"::Order, PurchHead."Document Type"::Invoice]) then
            exit;

        if PurchHead."Bank Code" = '' then
            exit;

        if not VendBank.Get(PurchHead."Pay-to Vendor No.", PurchHead."Bank Code") then
            Error(Text076Err, PurchHead."Bank Code", PurchHead."Pay-to Vendor No.");

        // Ref no. defined for ESR?
        if VendBank."Payment Form" in [VendBank."Payment Form"::ESR, VendBank."Payment Form"::"ESR+"] then
            if PurchHead."Reference No." = '' then
                Error(Text077Err, PurchHead."Document Type", PurchHead."No.", PurchHead."Bank Code", VendBank."Payment Form");

        if VendBank."Payment Form" = VendBank."Payment Form"::ESR then
            if -GLL.Amount <> PurchHead."ESR Amount" then
                Error(Text079Err, PurchHead."No.", -GLL.Amount, PurchHead."ESR Amount");

        GLL."Recipient Bank Account" := PurchHead."Bank Code";
        GLL."Reference No." := PurchHead."Reference No.";
        GLL.Checksum := PurchHead.Checksum;
    end;

    [Scope('OnPrem')]
    procedure ReleaseVendorLedgerEntries(GenJnlLine: Record "Gen. Journal Line")
    var
        VendEntry: Record "Vendor Ledger Entry";
    begin
        if (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor) and
           (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment)
        then begin
            VendEntry.Reset();
            VendEntry.SetCurrentKey("Document No.");
            VendEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            VendEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if VendEntry.FindFirst() then
                if VendEntry."On Hold" = 'DTA' then begin
                    VendEntry."On Hold" := '';
                    VendEntry.Modify();
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure StartYellownet()
    begin
        DtaSetup.SetRange("DTA/EZAG", DtaSetup."DTA/EZAG"::EZAG);
        if not DtaSetup.FindFirst() then
            Error(Text094Err);

        DtaSetup.TestField("Yellownet Home Page");
        HyperLink(DtaSetup."Yellownet Home Page");
    end;

    [Scope('OnPrem')]
    procedure ModifyDocNo(var GenJnlLine: Record "Gen. Journal Line")
    var
        ModifyDocNoInput: Page "Modify Document Number Input";
        NewDocNo: Code[20];
    begin
        NewDocNo := GenJnlLine."Document No.";

        ModifyDocNoInput.SetNewDocumentNo(NewDocNo);
        if ModifyDocNoInput.RunModal() = ACTION::OK then
            ModifyDocNoInput.GetNewDocumentNo(NewDocNo)
        else
            exit;

        if not Confirm(
             Text100Qst,
             true, GenJnlLine."Document No.", NewDocNo)
        then
            exit;

        GlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GlLine.ModifyAll("Document No.", NewDocNo);
    end;

    [Scope('OnPrem')]
    procedure ModifyExRate(GenJnlLine: Record "Gen. Journal Line")
    begin
        GlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GlLine.SetRange("Currency Code", GenJnlLine."Currency Code");
        GlLine.SetFilter("Line No.", '<>%1', GenJnlLine."Line No.");
        if GlLine.FindSet() then begin
            if not Confirm(
                 Text101Qst,
                 false, GlLine.Count, GenJnlLine."Currency Code")
            then
                exit;
            repeat
                GlLine.Validate("Currency Factor", GenJnlLine."Currency Factor");
                GlLine.Modify();
            until GlLine.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckEsrCurrency(CurrencyCode: Code[10]; ESRISRCodingLine: Code[70])
    var
        ESRTransactionCode: Integer;
        ISOCurrencyCode: Code[10];
    begin
        if StrLen(ESRISRCodingLine) > 12 then begin
            ISOCurrencyCode := GetIsoCurrencyCode(CurrencyCode);

            if not (ISOCurrencyCode in ['CHF', 'EUR']) then
                Error(Text110Err, ISOCurrencyCode);

            Evaluate(ESRTransactionCode, CopyStr(DelChr(ESRISRCodingLine, '=', '<'), 1, 2));
            if (ISOCurrencyCode = 'CHF') and (ESRTransactionCode > 20) then
                Error(Text111Err, ISOCurrencyCode);
            if (ISOCurrencyCode = 'EUR') and (ESRTransactionCode < 20) then
                Error(Text112Err, ISOCurrencyCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure IBANDELCHR(IBAN: Code[37]) PureIBAN: Code[37]
    begin
        // Delete all spaces and ':'
        PureIBAN := DelChr(IBAN);
        PureIBAN := DelChr(PureIBAN, '=', ':');

        // Delete 'IBAN' prefix
        if StrPos(PureIBAN, 'IBAN') <> 0 then
            PureIBAN := DelStr(PureIBAN, StrPos(PureIBAN, 'IBAN'), 4);

        exit(PureIBAN);
    end;

    [Scope('OnPrem')]
    procedure GetIsoCurrencyCode(CurrencyCode: Code[10]) IsoCurrencyCode: Code[10]
    begin
        GlSetup.Get();

        if CurrencyCode in ['', GlSetup."LCY Code"] then
            // ISO-Currency Code of LCY
            IsoCurrencyCode := 'CHF'
        else begin
            Currency.Get(CurrencyCode);
            if StrLen(Currency."ISO Code") <> 3 then
                Error(Text114Err, Currency."ISO Code", CurrencyCode);
            IsoCurrencyCode := Currency."ISO Code";
        end;
    end;

    [Scope('OnPrem')]
    procedure GetRecordType(xISO: Code[10]; Amount: Decimal; VendorNo: Code[20]; VendBankNo: Code[20]; DtaEzag: Code[10]) RecordType: Integer
    begin
        Clear(VendBank);

        if not VendBank.Get(VendorNo, VendBankNo) then
            Error(Text013Err, VendorNo, VendBankNo);

        case VendBank."Payment Form" of
            // ***** ESR & ESR+ *****
            VendBank."Payment Form"::ESR, VendBank."Payment Form"::"ESR+":
                if DtaEzag = 'DTA' then
                    case xISO of
                        'CHF':
                            RecordType := 826;
                        'EUR':
                            RecordType := 830;
                        else
                            Error(Text115Err, VendBank."Payment Form", VendorNo, Amount);
                    end
                else
                    case xISO of
                        'CHF':
                            RecordType := 28;
                        'EUR':
                            RecordType := 28;
                        else
                            Error(Text115Err, VendBank."Payment Form", VendorNo, Amount);
                    end;
            // ***** Postzahlung Inland *****
            VendBank."Payment Form"::"Post Payment Domestic":
                if DtaEzag = 'DTA' then
                    case xISO of
                        'CHF':
                            RecordType := 827;
                        'EUR':
                            RecordType := 830;
                        else
                            Error(Text115Err, VendBank."Payment Form", VendorNo, Amount);
                    end
                else
                    RecordType := 22;
            // ***** Bankzahlung Inland *****
            VendBank."Payment Form"::"Bank Payment Domestic":
                if DtaEzag = 'DTA' then begin
                    if xISO = 'CHF' then
                        RecordType := 827
                    else
                        RecordType := 830;
                end else
                    RecordType := 27;
            // ***** Zahlungsanweisung Inland *****
            VendBank."Payment Form"::"Cash Outpayment Order Domestic":
                begin
                    if DtaEzag = 'DTA' then
                        Error(Text116Err, VendBank."Payment Form", VendorNo, VendBankNo);
                    if not (xISO = 'CHF') then
                        Error(Text117Err, VendBank."Payment Form", VendorNo, Amount);
                    RecordType := 24
                end;
            // ***** Postzahlung Ausland *****
            VendBank."Payment Form"::"Post Payment Abroad":
                begin
                    if DtaEzag = 'DTA' then
                        Error(Text116Err, VendBank."Payment Form", VendorNo, VendBankNo);
                    RecordType := 32;
                end;
            // ***** Bankzahlung Ausland & SWIFT-Zahlung Ausland *****
            VendBank."Payment Form"::"Bank Payment Abroad", VendBank."Payment Form"::"SWIFT Payment Abroad":
                if DtaEzag = 'DTA' then
                    RecordType := 830
                else
                    RecordType := 37;
            // ***** Postanweisung Ausland *****
            VendBank."Payment Form"::"Cash Outpayment Order Abroad":
                begin
                    if DtaEzag = 'DTA' then
                        Error(Text116Err, VendBank."Payment Form", VendorNo, VendBankNo);
                    RecordType := 34;
                end;
        end;

        if (VendBank.IBAN <> '') and (RecordType in [827, 830]) then
            RecordType := 836;
    end;
}

