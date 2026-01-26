// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 7000007 "Document-Misc"
{
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "Cartera Doc." = imd,
                  TableData "Posted Cartera Doc." = imd,
                  TableData "Closed Cartera Doc." = imd,
                  TableData "Posted Bill Group" = imd,
                  TableData "Closed Bill Group" = imd;

    trigger OnRun()
    begin
    end;

    var
        Text1100000: Label 'This document is included in a posted bill group. Its %1 cannot be modified.';
        Text1100001: Label 'This document is closed. Its %1 cannot be modified.';
        Text1100002: Label 'This document is included in a posted payment order. Its %1 cannot be modified.';
        Text1100003: Label '%1 cannot be used in CSB Electronics Norms Exports.';
        Text1100004: Label '%1 cannot be used in CSB Electronic Norm Export No. 34./Norm Export No. 34.1';
        Text1100005: Label '%1 is not correct. Do you want to have it corrected?';
        Text1100006: Label 'This account has no control digit. Do you want to have it calculated?';
        Text1100007: Label 'Partial Bill settlement %1/%2';
        Text1100008: Label 'Partial Document settlement %1 Customer No. %2';
        Text1100009: Label 'Partial Document settlement %1';

    procedure UpdateReceivableDueDate(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        Doc: Record "Cartera Doc.";
    begin
        if CustLedgEntry."Document Situation" = CustLedgEntry."Document Situation"::" " then
            exit;
        case CustLedgEntry."Document Situation" of
            CustLedgEntry."Document Situation"::"BG/PO", CustLedgEntry."Document Situation"::Cartera:
                begin
                    Doc.Get(Doc.Type::Receivable, CustLedgEntry."Entry No.");
                    Doc.Validate("Due Date", CustLedgEntry."Due Date");
                    Doc.Modify();
                end;
            CustLedgEntry."Document Situation"::"Posted BG/PO":
                Error(
                  Text1100000,
                  CustLedgEntry.FieldCaption("Due Date"));
            CustLedgEntry."Document Situation"::"Closed BG/PO", CustLedgEntry."Document Situation"::"Closed Documents":
                Error(
                  Text1100001,
                  CustLedgEntry.FieldCaption("Due Date"));
        end;
    end;

    procedure UpdatePayableDueDate(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        Doc: Record "Cartera Doc.";
    begin
        if VendLedgEntry."Document Situation" = VendLedgEntry."Document Situation"::" " then
            exit;
        case VendLedgEntry."Document Situation" of
            VendLedgEntry."Document Situation"::"BG/PO", VendLedgEntry."Document Situation"::Cartera:
                begin
                    Doc.Get(Doc.Type::Payable, VendLedgEntry."Entry No.");
                    Doc."Due Date" := VendLedgEntry."Due Date";
                    Doc.Modify();
                end;
            VendLedgEntry."Document Situation"::"Posted BG/PO":
                Error(
                  Text1100002,
                  VendLedgEntry.FieldCaption("Due Date"));
            VendLedgEntry."Document Situation"::"Closed BG/PO", VendLedgEntry."Document Situation"::"Closed Documents":
                Error(
                  Text1100001,
                  VendLedgEntry.FieldCaption("Due Date"));
        end;
    end;

    procedure DocType(PmtMethodCode: Code[10]): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get(PmtMethodCode);
        case PaymentMethod."Bill Type" of
            PaymentMethod."Bill Type"::"Bill of Exchange":
                exit('1');
            PaymentMethod."Bill Type"::Receipt:
                exit('2');
            PaymentMethod."Bill Type"::IOU:
                exit('3');
            else
                Error(Text1100003, PmtMethodCode);
        end;
    end;

    procedure DocType2(PmtMethodCode: Code[10]): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get(PmtMethodCode);
        case PaymentMethod."Bill Type" of
            PaymentMethod."Bill Type"::Check:
                exit('4');
            PaymentMethod."Bill Type"::Transfer:
                exit('5');
            else
                Error(Text1100004, PmtMethodCode);
        end;
    end;

    procedure CalcControlDigit(Branch: Text[30]; Bank: Text[30]): Text[2]
    var
        CarteraSetup: Record "Cartera Setup";
        Weight: Text[30];
        Digit1: Integer;
        Digit2: Integer;
        i: Integer;
        BranchDigit: Integer;
        BankDigit: Integer;
        WeightDigit: Integer;
    begin
        CarteraSetup.Get();
        Weight := CarteraSetup."CCC Ctrl Digits Check String";
        Digit1 := 0;
        Digit2 := 0;

        for i := 1 to StrLen(Branch) do begin
            Evaluate(BranchDigit, CopyStr(Branch, StrLen(Branch) - i + 1, 1));
            case i of
                1 .. 4:
                    Evaluate(WeightDigit, CopyStr(Weight, i, 1));
                5:
                    Evaluate(WeightDigit, CopyStr(Weight, i, 2));
                6 .. 11:
                    Evaluate(WeightDigit, CopyStr(Weight, i + 1, 1));
            end;
            Digit1 := Digit1 + (BranchDigit * WeightDigit);
        end;
        Digit1 := 11 - (Digit1 mod 11);

        if Digit1 = 10 then
            Digit1 := 1;
        if Digit1 = 11 then
            Digit1 := 0;

        for i := 1 to StrLen(Bank) do begin
            Evaluate(BankDigit, CopyStr(Bank, StrLen(Bank) - i + 1, 1));
            case i of
                1 .. 4:
                    Evaluate(WeightDigit, CopyStr(Weight, i, 1));
                5:
                    Evaluate(WeightDigit, CopyStr(Weight, i, 2));
                6 .. 11:
                    Evaluate(WeightDigit, CopyStr(Weight, i + 1, 1));
            end;
            Digit2 := Digit2 + (BankDigit * WeightDigit);
        end;
        Digit2 := 11 - (Digit2 mod 11);

        if Digit2 = 10 then
            Digit2 := 1;
        if Digit2 = 11 then
            Digit2 := 0;

        exit(Format(Digit1) + Format(Digit2));
    end;

    procedure CheckControlDigit(var CustCCCControlDigits: Text[2]; CustCCCBankBranchNo: Text[30]; CustCCCAccNo: Text[30]; Cust2: Text[30])
    var
        CarteraSetup: Record "Cartera Setup";
        CustBankAcc: Record "Customer Bank Account";
        MessageTxt: Text[150];
    begin
        CarteraSetup.Get();
        if CarteraSetup."CCC Ctrl Digits Check String" <> '' then
            if CustCCCControlDigits <> '' then begin
                if CalcControlDigit(CustCCCBankBranchNo + Cust2, CustCCCAccNo) <> CustCCCControlDigits then begin
                    MessageTxt := StrSubstNo(
                        Text1100005,
                        CustBankAcc.FieldCaption("CCC Control Digits"));
                    if not Confirm(MessageTxt) then
                        CustCCCControlDigits := '**'
                    else
                        CustCCCControlDigits := CalcControlDigit(CustCCCBankBranchNo + Cust2, CustCCCAccNo);
                end
            end else
                if not Confirm(Text1100006) then
                    CustCCCControlDigits := '**'
                else
                    CustCCCControlDigits := CalcControlDigit(CustCCCBankBranchNo + Cust2, CustCCCAccNo)
        else
            if CustCCCControlDigits = '' then
                CustCCCControlDigits := '**';
    end;

    procedure FilterGLEntry(var GLEntry: Record "G/L Entry"; AccNo: Code[20]; DocNo: Code[20]; BillNo: Code[20]; TypeDoc: Option Bill,Invoice; CustAccNo: Code[20])
    var
        Description2: Text[50];
    begin
        GLEntry.SetCurrentKey("G/L Account No.", Description);
        GLEntry.SetRange("G/L Account No.", AccNo);
        if TypeDoc = TypeDoc::Bill then
            Description2 := CopyStr(
                StrSubstNo(Text1100007, DocNo, BillNo),
                1, MaxStrLen(GLEntry.Description))
        else
            if CustAccNo <> '' then
                Description2 := CopyStr(
                    StrSubstNo(Text1100008,
                      DocNo,
                      CustAccNo), 1, MaxStrLen(GLEntry.Description))
            else
                Description2 := CopyStr(
                    StrSubstNo(Text1100009, DocNo),
                    1, MaxStrLen(GLEntry.Description));
        GLEntry.SetRange(Description, Description2);
    end;

    procedure GetRegisterCode(CurrCode: Code[10]; var RegisterCode: Integer; var RegisterString: Text[2]): Boolean
    var
        CarteraSetup: Record "Cartera Setup";
    begin
        CarteraSetup.Get();
        if CurrCode = CarteraSetup."Euro Currency Code" then begin
            RegisterCode := 50;
            RegisterString := '65';
            exit(true);
        end;
    end;

    procedure CheckBankSuffix(SuffixBankAccNo: Code[20]; BillGrBankAccNo: Code[20]): Boolean
    begin
        if SuffixBankAccNo <> BillGrBankAccNo then
            exit(false);

        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Order", 'OnAfterInsertAllSalesOrderLines', '', false, false)]
    local procedure RecalculateDiscountOnAfterInsertAllSalesOrderLines(var SalesOrderLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header")
    begin
        if SalesQuoteHeader."Payment Discount %" <> 0 then
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesOrderLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Quote to Order", 'OnAfterInsertAllPurchOrderLines', '', false, false)]
    local procedure RecalculateDiscountOnAfterInsertAllPurchOrderLines(var PurchOrderLine: Record "Purchase Line"; PurchQuoteHeader: Record "Purchase Header")
    begin
        if PurchQuoteHeader."Payment Discount %" <> 0 then
            CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchOrderLine);
    end;
}

