// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Foundation.Period;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using System.Utilities;

codeunit 12104 LocalApplicationManagement
{

    trigger OnRun()
    begin
    end;

    var
        Text1033: Label 'AA';
        Text1034: Label 'ZZ';
        Text1035: Label 'aa';
        Text1036: Label 'zz';
        Text1037: Label '0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z';
        Text1038: Label 'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z';
        Text1039: Label 'Value is not correct.';
        Text1040: Label 'Value %1 is not correct.';
        Text1041: Label 'Data in position 8,9,10 (%1) is not correct. It must be <= %2.';
        Text1042: Label '%1 must be less than %2.';
        Text1043: Label 'Dates must have the same Month/Year.';
        Text1044: Label 'This month does not exist.';
        Text1045: Label '<Month Text>', Locked = true;
        CheckFiscalCodeSetup: Record "Check Fiscal Code Setup";
        Date: Record Date;
        StrLengthOfVar: Integer;
        i: Integer;
        Pos: Integer;
        RemainingVar: Integer;
        SubstractfromValue: Integer;
        Factor: Integer;
        UnitDigitOfCol3Integer: Integer;
        Value: Decimal;
        DivideByDecimal: Decimal;
        MainVar: Decimal;
        DecVar: array[10] of Decimal;
        ResultVar: Decimal;
        Col: array[3] of Decimal;
        Str1: Code[100];
        StrD: Code[150];
        StrP: Code[150];
        Str2: Code[100];
        Str3: Code[100];
        CodeWithOutCheckDigit: Code[20];
        CheckDigitVar: Code[1];
        CharVar: Code[1];
        ConvertedStr1: Code[100];
        ConvertedStr2: Code[100];
        ConvertedStrD: Code[100];
        ConvertedStrP: Code[100];
        Step5CodeVar: Code[2];
        RemainingVarTxt: Code[2];
        CodeVar: array[10] of Code[2];
        UnitDigitOfCol3Code: Code[1];
        Col3ConvToCode: Code[10];
        OddCharacter: Code[100];
        EvenCharacter: Code[100];
        AddRepError: Boolean;
        SkipMsgDisplay: Boolean;
        FieldModifyQst: Label '%1 will be modified according to %2. Do you want to continue?', Comment = '%1=Field name, %2=Another field name';
        ValueLessThanAnotherErr: Label '%1 cannot be less than %2.', Comment = '%1=Field name, %2=Another field name';
        PostingNoExistsQst: Label 'If you create an invoice based on order %1 with an existing posting number, it will cause a gap in the number series. \\Do you want to continue?', Comment = '%1=Document number';
        CancelledErr: Label 'Cancelled by user.';

    procedure CheckDigit(FiscalCode: Code[20])
    var
        NewStr: Code[10];
        Run: Decimal;
        SetValue: Option A,B,C,D,E,F;
    begin
        if StrLen(FiscalCode) = 11 then begin
            NewStr := CopyStr(FiscalCode, 2, 2);
            if (NewStr >= Text1033) and (NewStr <= Text1034) or (NewStr >= Text1035) and (NewStr <= Text1036) then
                exit;
            CheckDigitVAT(FiscalCode);
            exit;
        end;
        if StrLen(FiscalCode) <> 16 then begin
            SetValue := SetValue::A;
            ErrorMessage(SetValue, 0, 0, '');
            exit;
        end;
        DivideByDecimal := 26;

        InitiateCheckFiscalCodeSetup();
        Str1 := CheckFiscalCodeSetup.Str1;
        StrD := CheckFiscalCodeSetup.StrD;
        StrP := CheckFiscalCodeSetup.StrP;
        Str2 := CheckFiscalCodeSetup.Str2;
        Str3 := CheckFiscalCodeSetup.Str3;

        Run := 0;

        // Step 1
        StrLengthOfVar := StrLen(FiscalCode);
        if StrLengthOfVar <= 2 then begin
            SetValue := SetValue::A;
            ErrorMessage(SetValue, 0, 0, '');
        end;
        CodeWithOutCheckDigit := CopyStr(FiscalCode, 1, StrLengthOfVar - 1);
        CheckDigitVar := CopyStr(FiscalCode, StrLengthOfVar, 1);

        i := 0;
        repeat
            i := i + 1;
            OddCharacter := OddCharacter + CopyStr(CodeWithOutCheckDigit, i, 1);
            i := i + 1;
            EvenCharacter := EvenCharacter + CopyStr(CodeWithOutCheckDigit, i, 1);
        until i >= StrLengthOfVar;

        // Step 2
        ConvertedStr1 := DelChr(Str1, '=', ',');
        ConvertedStrD := DelChr(StrD, '=', ',');

        StrLengthOfVar := 0;
        StrLengthOfVar := StrLen(OddCharacter);
        i := 0;
        repeat
            i := i + 1;
            CharVar := '';
            Pos := 0;
            Value := 0;
            CharVar := CopyStr(OddCharacter, i, 1);
            Pos := StrPos(ConvertedStr1, CharVar);
            if Pos = 0 then begin
                SetValue := SetValue::A;
                ErrorMessage(SetValue, 0, 0, '');
            end;
            Evaluate(Value, CopyStr(ConvertedStrD, (Pos * 2) - 1, 2));
            Run := Run + Value;
        until i = StrLengthOfVar;

        // Step 3
        ConvertedStrP := DelChr(StrP, '=', ',');
        StrLengthOfVar := 0;
        StrLengthOfVar := StrLen(EvenCharacter);
        i := 0;
        repeat
            i := i + 1;
            CharVar := '';
            Pos := 0;
            Value := 0;
            CharVar := CopyStr(EvenCharacter, i, 1);
            Pos := StrPos(ConvertedStr1, CharVar);
            if Pos = 0 then begin
                SetValue := SetValue::A;
                ErrorMessage(SetValue, 0, 0, '');
            end;
            Evaluate(Value, CopyStr(ConvertedStrP, (Pos * 2) - 1, 2));
            Run := Run + Value;
        until i = StrLengthOfVar;

        // Step 4
        MainVar := Round(Run / DivideByDecimal, 1, '<');
        MainVar := DivideByDecimal * MainVar;
        RemainingVar := Run - MainVar;

        // Step 5
        ConvertedStr2 := DelChr(Str2, '=', ',');
        StrLengthOfVar := 0;
        StrLengthOfVar := StrLen(ConvertedStr2);
        i := 1;
        Pos := 0;
        Step5CodeVar := '';
        if RemainingVar < 10 then
            RemainingVarTxt := '0' + Format(RemainingVar)
        else
            RemainingVarTxt := Format(RemainingVar);
        repeat
            Pos := Pos + 1;
            Step5CodeVar := CopyStr(ConvertedStr2, i, 2);
            i := i + 2;
        until (Step5CodeVar = RemainingVarTxt) or (Pos = StrLengthOfVar);

        // Step 6
        if Step5CodeVar <> RemainingVarTxt then begin
            SetValue := SetValue::B;
            ErrorMessage(SetValue, 0, 0, CheckDigitVar);
        end else
            if CheckDigitVar <> SelectStr(Pos, Str3) then begin
                SetValue := SetValue::B;
                ErrorMessage(SetValue, 0, 0, CheckDigitVar);
            end;
    end;

    [Scope('OnPrem')]
    procedure InitiateCheckFiscalCodeSetup()
    begin
        if not CheckFiscalCodeSetup.Get() then begin
            CheckFiscalCodeSetup.Init();
            CheckFiscalCodeSetup.Insert();
        end;

        if not CheckFiscalCodeSetup."Initiated Values" then begin
            CheckFiscalCodeSetup.Str1 := Text1037;

            CheckFiscalCodeSetup.StrD :=
              '01,00,05,07,09,13,15,17,19,21,01,00,05,07,09,13,15,17,19,21,02,04,18,20,11,03,06,08,12,14,16,10,22,25,24,23';

            CheckFiscalCodeSetup.StrP :=
              '00,01,02,03,04,05,06,07,08,09,00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25';

            CheckFiscalCodeSetup.Str2 := '00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25';
            CheckFiscalCodeSetup.Str3 := Text1038;
            CheckFiscalCodeSetup."Initiated Values" := true;
            CheckFiscalCodeSetup.Modify();
        end;

        CheckFiscalCodeSetup.TestField(Str1);
        CheckFiscalCodeSetup.TestField(StrD);
        CheckFiscalCodeSetup.TestField(StrP);
        CheckFiscalCodeSetup.TestField(Str2);
        CheckFiscalCodeSetup.TestField(Str3);
    end;

    [Scope('OnPrem')]
    procedure ErrorMessage(FindErrorMessage: Option A,B,C,D,E,F; FixedValue: Decimal; ActualValue: Decimal; CheckDigit: Code[1])
    begin
        if not SkipMsgDisplay then
            case FindErrorMessage of
                FindErrorMessage::A:
                    Message(Text1039);
                FindErrorMessage::B:
                    Message(Text1040, CheckDigit);
                FindErrorMessage::C:
                    Message(Text1041, ActualValue, FixedValue);
            end;
        AddRepError := FindErrorMessage in [FindErrorMessage::A, FindErrorMessage::B, FindErrorMessage::C];
    end;

    procedure CheckDigitVAT(VATCode: Text[20])
    var
        SetValue: Option A,B,C,D,E,F;
    begin
        if VATCode = '' then
            exit;

        SubstractfromValue := 10;
        Factor := 2;

        // Step 1
        StrLengthOfVar := StrLen(VATCode);
        if StrLengthOfVar < 11 then
            ErrorMessage(SetValue::A, 0, 0, '');

        CodeWithOutCheckDigit := CopyStr(VATCode, 1, StrLengthOfVar - 1);
        CheckDigitVar := CopyStr(VATCode, StrLengthOfVar, 1);

        i := 0;

        Clear(OddCharacter);
        Clear(EvenCharacter);

        repeat
            i := i + 1;
            OddCharacter := OddCharacter + CopyStr(CodeWithOutCheckDigit, i, 1);
            i := i + 1;
            EvenCharacter := EvenCharacter + CopyStr(CodeWithOutCheckDigit, i, 1);
        until i >= StrLengthOfVar;

        // Step 2
        StrLengthOfVar := 0;
        StrLengthOfVar := StrLen(EvenCharacter);
        i := 0;
        Clear(DecVar);
        repeat
            i := i + 1;
            Evaluate(DecVar[i], CopyStr(EvenCharacter, i, 1));
            DecVar[i] := DecVar[i] * Factor;
        until i = StrLengthOfVar;

        // Step 3
        i := 0;
        Clear(CodeVar);
        Clear(ResultVar);
        Clear(Col);

        repeat
            i := i + 1;
            CodeVar[i] := Format(DecVar[i]);
            case StrLen(CodeVar[i]) of
                1:
                    begin
                        Clear(ResultVar);
                        Evaluate(ResultVar, CodeVar[i]);
                        Col[2] := Col[2] + ResultVar;
                    end;
                2:
                    begin
                        Clear(ResultVar);
                        Evaluate(ResultVar, CopyStr(CodeVar[i], 1, 1));
                        Col[1] := Col[1] + ResultVar;
                        Clear(ResultVar);
                        Evaluate(ResultVar, CopyStr(CodeVar[i], 2, 1));
                        Col[2] := Col[2] + ResultVar;
                    end;
            end;
        until i = 10; // MAX of even characters multiplied by factor 2

        // Step 4
        Col[3] := Col[1] + Col[2];

        // Step 5
        StrLengthOfVar := 0;
        StrLengthOfVar := StrLen(OddCharacter);
        i := 0;
        Clear(DecVar);
        repeat
            i := i + 1;
            Evaluate(DecVar[i], CopyStr(OddCharacter, i, 1));
            Col[3] := Col[3] + DecVar[i];
        until i = StrLengthOfVar;

        // Step 6
        StrLengthOfVar := 0;
        UnitDigitOfCol3Code := '';
        Col3ConvToCode := '';

        Col3ConvToCode := Format(Col[3]);
        StrLengthOfVar := StrLen(Col3ConvToCode);
        UnitDigitOfCol3Code := CopyStr(Col3ConvToCode, StrLengthOfVar, 1);

        if UnitDigitOfCol3Code <> '0' then begin
            Evaluate(UnitDigitOfCol3Integer, UnitDigitOfCol3Code);
            if Format(SubstractfromValue - UnitDigitOfCol3Integer) <> CheckDigitVar then
                ErrorMessage(SetValue::B, 0, 0, CheckDigitVar);
        end else
            if Format(UnitDigitOfCol3Integer) <> CheckDigitVar then
                ErrorMessage(SetValue::B, 0, 0, CheckDigitVar);
    end;

    procedure CheckData(FirstDate: Date; SecondDate: Date; Text1: Text[30]; Text2: Text[30])
    begin
        if FirstDate > SecondDate then
            Error(Text1042, Text1, Text2);
    end;

    procedure CheckSameMonth(FirstDate: Date; SecondDate: Date)
    begin
        if (Date2DMY(FirstDate, 2) <> Date2DMY(SecondDate, 2)) or (Date2DMY(FirstDate, 3) <> Date2DMY(SecondDate, 3)) then
            Error(Text1043);
    end;

    procedure ConvertToNumeric(DocNo: Code[20]; MaxStrLength: Integer): Code[20]
    begin
        if MaxStrLength > MaxStrLen(DocNo) then
            MaxStrLength := MaxStrLen(DocNo);
        DocNo := DelChr(Format(DocNo, MaxStrLength), '=', DelChr(DocNo, '=', '1234567890'));
        DocNo := DelChr(DocNo, '=', ' ');
        if StrLen(DocNo) < MaxStrLength then
            DocNo := PadStr('', MaxStrLength - StrLen(DocNo), '0') + DocNo;
        exit(DocNo);
    end;

    [Scope('OnPrem')]
    procedure IsLeapYear(Year: Integer) LeapYear: Boolean
    var
        Century: Integer;
    begin
        Century := Date2DMY(WorkDate(), 3) div 100;

        if Year < 100 then
            Year := Year + Century * 100;

        if (Year mod 4) = 0 then
            LeapYear := true
        else
            LeapYear := false;
    end;

    [Scope('OnPrem')]
    procedure MaxDay(Month: Integer; Year: Integer) MaxDay: Integer
    begin
        if Date.Get(Date."Period Type"::Month, DMY2Date(1, Month, Year)) then
            MaxDay := Date2DMY(Date."Period End", 1)
        else
            Error(Text1044);
    end;

    [Scope('OnPrem')]
    procedure GetMonth(MonthNo: Integer) MonthDescr: Text[15]
    begin
        MonthDescr := '';

        if (MonthNo > 0) and (MonthNo < 13) then
            MonthDescr := Format(DMY2Date(1, MonthNo, 1998), 0, Text1045);
    end;

    [Scope('OnPrem')]
    procedure GetErrorStatus(var AddRepError2: Boolean)
    begin
        AddRepError2 := AddRepError;
    end;

    [Scope('OnPrem')]
    procedure SkipErrorMsg(SkipMsgDisplay2: Boolean)
    begin
        SkipMsgDisplay := SkipMsgDisplay2;
    end;

    [Scope('OnPrem')]
    procedure ValidateOperationOccurredDate(var RecordRef: RecordRef; HideValidationDialog: Boolean)
    var
        PostingDateFieldRef: FieldRef;
        OccurredDateFieldRef: FieldRef;
        PostingDate: Date;
        OperationOccuredDate: Date;
    begin
        PostingDateFieldRef := RecordRef.Field(20);
        OccurredDateFieldRef := RecordRef.Field(12101);

        PostingDate := PostingDateFieldRef.Value();
        OperationOccuredDate := OccurredDateFieldRef.Value();

        if OperationOccuredDate = 0D then
            OccurredDateFieldRef.Validate(PostingDate);
        if OperationOccuredDate > PostingDate then
            ValidateOccurredDateIfConfirm(PostingDateFieldRef, OccurredDateFieldRef, HideValidationDialog);
        if OperationOccuredDate < PostingDate then
            if GetNotifyOnOccurredDateChangeSetup(RecordRef) then
                ValidateOccurredDateIfConfirm(PostingDateFieldRef, OccurredDateFieldRef, HideValidationDialog)
            else
                OccurredDateFieldRef.Validate(PostingDate);

        OperationOccuredDate := OccurredDateFieldRef.Value();
        if OperationOccuredDate > PostingDate then
            Error(ValueLessThanAnotherErr, PostingDateFieldRef.Caption, OccurredDateFieldRef.Caption);
    end;

    local procedure ValidateOccurredDateIfConfirm(PostingDateFieldRef: FieldRef; OccurredDateFieldRef: FieldRef; HideValidationDialog: Boolean)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        Confirmed: Boolean;
    begin
        if HideValidationDialog then
            Confirmed := true
        else
            Confirmed := ConfirmManagement.GetResponseOrDefault(
                StrSubstNo(FieldModifyQst, OccurredDateFieldRef.Caption, PostingDateFieldRef.Caption), true);
        if Confirmed then
            OccurredDateFieldRef.Validate(PostingDateFieldRef.Value);
    end;

    local procedure GetNotifyOnOccurredDateChangeSetup(RecRef: RecordRef) NotifyOnOccirDateChange: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        case RecRef.Number of
            DATABASE::"Sales Header":
                begin
                    SalesReceivablesSetup.Get();
                    exit(SalesReceivablesSetup."Notify On Occur. Date Change");
                end;
            DATABASE::"Purchase Header":
                begin
                    PurchasesPayablesSetup.Get();
                    exit(PurchasesPayablesSetup."Notify On Occur. Date Change");
                end;
            else
                OnGetNotifyOnOccurredDateChangeSetup(RecRef, NotifyOnOccirDateChange);
        end;
    end;

    local procedure CheckOriginalOrderPostingNo(var PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        PurchRcptHeader2: Record "Purch. Rcpt. Header";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        PurchRcptLine2.Copy(PurchRcptLine);
        PurchaseHeader.SetFilter("Posting No.", '<>%1', '');
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        if PurchRcptLine2.FindSet() then
            repeat
                if PurchRcptHeader2.Get(PurchRcptLine2."Document No.") then begin
                    PurchaseHeader.SetRange("No.", PurchRcptHeader2."Order No.");
                    if PurchaseHeader.FindFirst() then
                        exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(PostingNoExistsQst, PurchaseHeader."No."), true));
                end;
            until PurchRcptLine2.Next() = 0;
        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Get Receipt", 'OnCreateInvLinesOnBeforeFind', '', true, true)]
    local procedure CheckPostingNoOnCreateInvLinesOnBeforeFind(var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        if not CheckOriginalOrderPostingNo(PurchRcptLine) then
            Error(CancelledErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1312, 'OnAfterSetFilterForExternalDocNo', '', false, false)]
    local procedure OnAfterSetFilterForExternalDocNo(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentDate: Date)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        FYPeriodFilter: Text[30];
        FYPeriodName: Text[30];
    begin
        PurchasesPayablesSetup.Get();
        if not PurchasesPayablesSetup."Same Ext. Doc. No. in Diff. FY" then
            exit;

        case PurchasesPayablesSetup."Ext. Doc. No. Period Source" of
            PurchasesPayablesSetup."Ext. Doc. No. Period Source"::"Calendar Year":
                VendorLedgerEntry.SetRange("Document Date", CalcDate('<-CY>', DocumentDate), CalcDate('<CY>', DocumentDate));
            PurchasesPayablesSetup."Ext. Doc. No. Period Source"::"Fiscal Year":
                begin
                    DateFilterCalc.CreateFiscalYearFilter(FYPeriodFilter, FYPeriodName, DocumentDate, 0);
                    VendorLedgerEntry.SetFilter("Document Date", FYPeriodFilter);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNotifyOnOccurredDateChangeSetup(RecRef: RecordRef; var NotifyOnOccirDateChange: Boolean)
    begin
    end;
}

