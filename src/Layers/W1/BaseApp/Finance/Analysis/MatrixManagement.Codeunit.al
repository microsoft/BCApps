// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

codeunit 9200 "Matrix Management"
{

    trigger OnRun()
    begin
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLSetupRead: Boolean;

#pragma warning disable AA0074
        Text001: Label 'The previous column set could not be found.';
        Text002: Label 'The period could not be found.';
        Text003: Label 'There are no Calendar entries within the filter.';
#pragma warning restore AA0074
        RoundingFormatTxt: Label '<Precision,%1><Standard Format,0>%2', Locked = true;
        NegativeInParenthesesFormatTxt: Label ';(#,##0.00)', Locked = true;

    procedure SetPeriodColumnSet(DateFilter: Text; PeriodType: Enum "Analysis Period Type"; Direction: Option Backward,Forward; var FirstColumn: Date; var LastColumn: Date; NoOfColumns: Integer)
    var
        Period: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
        Steps: Integer;
        TmpFirstColumn: Date;
        TmpLastColumn: Date;
    begin
        Period.SetRange("Period Type", PeriodType);
        if DateFilter = '' then begin
            Period."Period Start" := WorkDate();
            if PeriodPageMgt.FindDate('<=', Period, PeriodType) then
                Steps := 1;
            PeriodPageMgt.NextDate(Steps, Period, PeriodType);
            DateFilter := '>=' + Format(Period."Period Start");
        end else begin
            Period.SetFilter("Period Start", DateFilter);
            Period.Find('-');
        end;

        if (Format(FirstColumn) = '') and (Format(LastColumn) = '') then begin
            FirstColumn := Period."Period Start";
            Period.Next(NoOfColumns - 1);
            LastColumn := Period."Period Start";
            exit;
        end;

        if Direction = Direction::Forward then begin
            Period.SetFilter("Period Start", DateFilter);
            if Period.Get(PeriodType, LastColumn) then
                Period.Next();
            TmpFirstColumn := Period."Period Start";
            Period.Next(NoOfColumns - 1);
            TmpLastColumn := Period."Period Start";
            if TmpFirstColumn <> LastColumn then begin
                FirstColumn := TmpFirstColumn;
                LastColumn := TmpLastColumn;
            end;
            exit;
        end;

        if Direction = Direction::Backward then begin
            if Period.Get(PeriodType, FirstColumn) then
                Period.Next(-1);
            TmpLastColumn := Period."Period Start";
            Period.Next(-NoOfColumns + 1);
            TmpFirstColumn := Period."Period Start";
            if TmpLastColumn <> FirstColumn then begin
                FirstColumn := TmpFirstColumn;
                LastColumn := TmpLastColumn;
            end;
        end;
    end;

    procedure SetDimColumnSet(DimensionCode: Code[20]; DimFilter: Text; SetWanted: Option; var RecordPosition: Text; var FirstColumn: Text; var LastColumn: Text; NoOfColumns: Integer)
    var
        DimVal: Record "Dimension Value";
        TmpFirstColumn: Text[1024];
        TmpLastColumn: Text[1024];
        TmpSteps: Integer;
    begin
        DimVal.SetRange("Dimension Code", DimensionCode);
        if DimFilter <> '' then
            DimVal.SetFilter(Code, DimFilter);
        OnSetDimColumnSetOnAfterDimValSetFilters(DimensionCode, DimFilter, DimVal);

        case "Matrix Page Step Type".FromInteger(SetWanted) of
            "Matrix Page Step Type"::Initial:
                if DimVal.Find('-') then begin
                    RecordPosition := DimVal.GetPosition();
                    FirstColumn := DimVal.Code;
                    TmpSteps := DimVal.Next(NoOfColumns - 1);
                    LastColumn := DimVal.Code;
                end;
            "Matrix Page Step Type"::Same:
                if RecordPosition <> '' then begin
                    DimVal.SetPosition(RecordPosition);
                    DimVal.Find('=');
                    FirstColumn := DimVal.Code;
                    TmpSteps := DimVal.Next(NoOfColumns - 1);
                    LastColumn := DimVal.Code;
                end;
            "Matrix Page Step Type"::Next:
                if RecordPosition <> '' then begin
                    DimVal.SetPosition(RecordPosition);
                    DimVal.Find('=');
                    if DimVal.Next(NoOfColumns) <> 0 then begin
                        RecordPosition := DimVal.GetPosition();
                        TmpFirstColumn := DimVal.Code;
                        TmpSteps := DimVal.Next(NoOfColumns - 1);
                        TmpLastColumn := DimVal.Code;
                        if TmpFirstColumn <> LastColumn then begin
                            FirstColumn := TmpFirstColumn;
                            LastColumn := TmpLastColumn;
                        end;
                    end else
                        SetDimColumnSet(
                            DimensionCode, DimFilter, "Matrix Page Step Type"::Same.AsInteger(), RecordPosition, FirstColumn, LastColumn, NoOfColumns);
                end;
            "Matrix Page Step Type"::Previous:
                if RecordPosition <> '' then begin
                    DimVal.SetPosition(RecordPosition);
                    DimVal.Find('=');
                    if DimVal.Next(-1) <> 0 then begin
                        TmpLastColumn := DimVal.Code;
                        TmpSteps := DimVal.Next(-NoOfColumns + 1);
                        RecordPosition := DimVal.GetPosition();
                        TmpFirstColumn := DimVal.Code;
                        if TmpLastColumn <> FirstColumn then begin
                            FirstColumn := TmpFirstColumn;
                            LastColumn := TmpLastColumn;
                        end;
                    end else
                        SetDimColumnSet(
                            DimensionCode, DimFilter, "Matrix Page Step Type"::Same.AsInteger(), RecordPosition, FirstColumn, LastColumn, NoOfColumns);
                end;
            "Matrix Page Step Type"::NextColumn:
                if RecordPosition <> '' then begin
                    DimVal.SetPosition(RecordPosition);
                    DimVal.Find('=');
                    if DimVal.Next() <> 0 then begin
                        RecordPosition := DimVal.GetPosition();
                        TmpFirstColumn := DimVal.Code;
                        TmpSteps := DimVal.Next(NoOfColumns - 1);
                        TmpLastColumn := DimVal.Code;
                        if TmpFirstColumn <> LastColumn then begin
                            FirstColumn := TmpFirstColumn;
                            LastColumn := TmpLastColumn;
                        end;
                    end else
                        SetDimColumnSet(
                            DimensionCode, DimFilter, "Matrix Page Step Type"::Same.AsInteger(), RecordPosition, FirstColumn, LastColumn, NoOfColumns);
                end;
            "Matrix Page Step Type"::PreviousColumn:
                if RecordPosition <> '' then begin
                    DimVal.SetPosition(RecordPosition);
                    DimVal.Find('=');
                    if DimVal.Next(-1) <> 0 then begin
                        RecordPosition := DimVal.GetPosition();
                        TmpFirstColumn := DimVal.Code;
                        TmpSteps := DimVal.Next(NoOfColumns - 1);
                        TmpLastColumn := DimVal.Code;
                        if TmpLastColumn <> FirstColumn then begin
                            FirstColumn := TmpFirstColumn;
                            LastColumn := TmpLastColumn;
                        end;
                    end else
                        SetDimColumnSet(
                            DimensionCode, DimFilter, "Matrix Page Step Type"::Same.AsInteger(), RecordPosition, FirstColumn, LastColumn, NoOfColumns);
                end;
        end;

        if Abs(TmpSteps) <> NoOfColumns then
            NoOfColumns := Abs(TmpSteps);
    end;

    procedure DimToCaptions(var CaptionSet: array[32] of Text[80]; var MatrixRecords: array[32] of Record "Dimension Code Buffer"; DimensionCode: Code[20]; FirstColumn: Text; LastColumn: Text; var NumberOfColumns: Integer; ShowColumnName: Boolean; var CaptionRange: Text; DimensionValueFilter: Text)
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetRange(Code, FirstColumn, LastColumn);
        DimensionValue.FilterGroup(7);
        if DimensionValueFilter <> '' then
            DimensionValue.SetFilter(Code, DimensionValueFilter);
        DimensionValue.FilterGroup(0);

        i := 0;
        if DimensionValue.FindSet() then
            repeat
                i := i + 1;
                MatrixRecords[i].Code := DimensionValue.Code;
                MatrixRecords[i].Name := DimensionValue.Name;
                MatrixRecords[i].Totaling := DimensionValue.Totaling;
                if ShowColumnName then
                    CaptionSet[i] := DimensionValue.Name
                else
                    CaptionSet[i] := DimensionValue.Code
            until (i = ArrayLen(CaptionSet)) or (DimensionValue.Next() = 0);

        NumberOfColumns := i;

        if NumberOfColumns > 1 then
            CaptionRange := CopyStr(CaptionSet[1] + '..' + CaptionSet[NumberOfColumns], 1, MaxStrLen(CaptionRange))
        else
            CaptionRange := CaptionSet[1];
    end;

    procedure GenerateMatrixData(var RecRef: RecordRef; SetWanted: Option; MaximumSetLength: Integer; CaptionFieldNo: Integer; var RecordPosition: Text; var CaptionSet: array[32] of Text[80]; var CaptionRange: Text; var CurrSetLength: Integer)
    begin
        GenerateMatrixDataExtended(
          RecRef, SetWanted, MaximumSetLength, CaptionFieldNo, RecordPosition, CaptionSet, CaptionRange, CurrSetLength, 80);
    end;

    procedure GenerateMatrixDataExtended(var RecRef: RecordRef; SetWanted: Option; MaximumSetLength: Integer; CaptionFieldNo: Integer; var RecordPosition: Text; var CaptionSet: array[32] of Text; var CaptionRange: Text; var CurrSetLength: Integer; MaxCaptionLength: Integer)
    var
        Steps: Integer;
        Caption: Text;
        IsHandled: Boolean;
    begin
        Clear(CaptionSet);
        CaptionRange := '';
        CurrSetLength := 0;

        if RecRef.IsEmpty() then begin
            RecordPosition := '';
            exit;
        end;

        case "Matrix Page Step Type".FromInteger(SetWanted) of
            "Matrix Page Step Type"::Initial:
                RecRef.FindFirst();
            "Matrix Page Step Type"::Previous:
                begin
                    RecRef.SetPosition(RecordPosition);
                    RecRef.Get(RecRef.RecordId);
                    Steps := RecRef.Next(-MaximumSetLength);
                    IsHandled := false;
                    OnGenerateMatrixDataExtendedOnBeforeValidatePreviousStep(Steps, MaximumSetLength, IsHandled);
                    if not IsHandled then
                        if not (Steps in [-MaximumSetLength .. 0]) then
                            Error(Text001);
                end;
            "Matrix Page Step Type"::Same:
                begin
                    RecRef.SetPosition(RecordPosition);
                    RecRef.Get(RecRef.RecordId);
                end;
            "Matrix Page Step Type"::Next:
                begin
                    RecRef.SetPosition(RecordPosition);
                    RecRef.Get(RecRef.RecordId);
                    if not (RecRef.Next(MaximumSetLength) = MaximumSetLength) then begin
                        RecRef.SetPosition(RecordPosition);
                        RecRef.Get(RecRef.RecordId);
                    end;
                end;
            "Matrix Page Step Type"::PreviousColumn:
                begin
                    RecRef.SetPosition(RecordPosition);
                    RecRef.Get(RecRef.RecordId);
                    Steps := RecRef.Next(-1);
                    if not (Steps in [-1, 0]) then
                        Error(Text001);
                end;
            "Matrix Page Step Type"::NextColumn:
                begin
                    RecRef.SetPosition(RecordPosition);
                    RecRef.Get(RecRef.RecordId);
                    if not (RecRef.Next(1) = 1) then begin
                        RecRef.SetPosition(RecordPosition);
                        RecRef.Get(RecRef.RecordId);
                    end;
                end;
            else
                OnMatrixPageStepTypeInGenerateMatrixDataExtended(SetWanted, MaximumSetLength, RecRef);
        end;

        RecordPosition := RecRef.GetPosition();

        repeat
            CurrSetLength := CurrSetLength + 1;
            Caption := GetCaption(RecRef, CaptionFieldNo);
            if StrLen(Caption) <= MaxCaptionLength then
                CaptionSet[CurrSetLength] := CopyStr(Caption, 1, MaxCaptionLength)
            else
                CaptionSet[CurrSetLength] := CopyStr(Caption, 1, MaxCaptionLength - 3) + '...';
        until (CurrSetLength = MaximumSetLength) or (RecRef.Next() <> 1);

        if CurrSetLength = 1 then
            CaptionRange := CaptionSet[1]
        else
            CaptionRange := CaptionSet[1] + '..' + CaptionSet[CurrSetLength];
    end;

    local procedure GetCaption(var RecRef: RecordRef; CaptionFieldNo: Integer) Caption: Text;
    begin
        Caption := Format(RecRef.Field(CaptionFieldNo).Value);
        OnAfterGetCaption(RecRef, CaptionFieldNo, Caption);
    end;

    procedure GeneratePeriodMatrixData(SetWanted: Option; MaximumSetLength: Integer; UseNameForCaption: Boolean; PeriodType: Enum "Analysis Period Type"; DateFilter: Text; var RecordPosition: Text; var CaptionSet: array[32] of Text[80]; var CaptionRange: Text; var CurrSetLength: Integer; var PeriodRecords: array[32] of Record Date temporary)
    var
        Calendar: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
        Steps: Integer;
        IsHandled: Boolean;
    begin
        Clear(CaptionSet);
        CaptionRange := '';
        CurrSetLength := 0;
        Clear(PeriodRecords);
        Clear(Calendar);
        Clear(PeriodPageMgt);

        Calendar.SetFilter("Period Start", PeriodPageMgt.GetFullPeriodDateFilter(PeriodType, DateFilter));

        if not FindDate('-', Calendar, PeriodType, false) then begin
            RecordPosition := '';
            Error(Text003);
        end;

        OnGeneratePeriodMatrixDataOnBeforeFindDateBasedOnStepType(SetWanted, Calendar, PeriodType);

        case "Matrix Page Step Type".FromInteger(SetWanted) of
            "Matrix Page Step Type"::Initial:
                begin
                    if (PeriodType = PeriodType::"Accounting Period") or (DateFilter <> '') then
                        FindDate('-', Calendar, PeriodType, true)
                    else
                        Calendar."Period Start" := 0D;
                    FindDate('=><', Calendar, PeriodType, true);
                end;
            "Matrix Page Step Type"::Previous:
                begin
                    Calendar.SetPosition(RecordPosition);
                    FindDate('=', Calendar, PeriodType, true);
                    Steps := PeriodPageMgt.NextDate(-MaximumSetLength, Calendar, PeriodType);
                    if not (Steps in [-MaximumSetLength .. 0]) then
                        Error(Text001);
                end;
            "Matrix Page Step Type"::PreviousColumn:
                begin
                    Calendar.SetPosition(RecordPosition);
                    FindDate('=', Calendar, PeriodType, true);
                    Steps := PeriodPageMgt.NextDate(-1, Calendar, PeriodType);
                    if not (Steps in [-1, 0]) then
                        Error(Text001);
                end;
            "Matrix Page Step Type"::NextColumn:
                begin
                    Calendar.SetPosition(RecordPosition);
                    FindDate('=', Calendar, PeriodType, true);
                    if not (PeriodPageMgt.NextDate(1, Calendar, PeriodType) = 1) then begin
                        Calendar.SetPosition(RecordPosition);
                        FindDate('=', Calendar, PeriodType, true);
                    end;
                end;
            "Matrix Page Step Type"::Same:
                begin
                    Calendar.SetPosition(RecordPosition);
                    FindDate('=', Calendar, PeriodType, true)
                end;
            "Matrix Page Step Type"::Next:
                begin
                    Calendar.SetPosition(RecordPosition);
                    FindDate('=', Calendar, PeriodType, true);
                    if not (PeriodPageMgt.NextDate(MaximumSetLength, Calendar, PeriodType) = MaximumSetLength) then begin
                        Calendar.SetPosition(RecordPosition);
                        FindDate('=', Calendar, PeriodType, true);
                    end;
                end;
        end;

        RecordPosition := Calendar.GetPosition();

        repeat
            GeneratePeriodAndCaption(CaptionSet, PeriodRecords, CurrSetLength, Calendar, UseNameForCaption, PeriodType);
        until (CurrSetLength = MaximumSetLength) or (PeriodPageMgt.NextDate(1, Calendar, PeriodType) <> 1);

        if CurrSetLength = 1 then
            CaptionRange := CaptionSet[1]
        else
            CaptionRange := CaptionSet[1] + '..' + CaptionSet[CurrSetLength];

        IsHandled := false;
        OnGeneratePeriodMatrixDataOnBeforeAdjustPeriodWithDateFilter(DateFilter, PeriodRecords, CurrSetLength, IsHandled);
        if not IsHandled then
            AdjustPeriodWithDateFilter(DateFilter, PeriodRecords[1]."Period Start",
              PeriodRecords[CurrSetLength]."Period End");
    end;

    local procedure GeneratePeriodAndCaption(var CaptionSet: array[32] of Text[80]; var PeriodRecords: array[32] of Record Date temporary; var CurrSetLength: Integer; var Calendar: Record Date; UseNameForCaption: Boolean; PeriodType: Enum "Analysis Period Type")
    var
        PeriodPageMgt: Codeunit PeriodPageManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGeneratePeriodAndCaption(PeriodType, Calendar, IsHandled, UseNameForCaption, CurrSetLength, CaptionSet, PeriodRecords);
        if IsHandled then
            exit;

        CurrSetLength := CurrSetLength + 1;
        if UseNameForCaption then
            CaptionSet[CurrSetLength] := Format(Calendar."Period Name")
        else
            CaptionSet[CurrSetLength] := PeriodPageMgt.CreatePeriodFormat(PeriodType, Calendar."Period Start");
        PeriodRecords[CurrSetLength].Copy(Calendar);
    end;

    local procedure FindDate(SearchString: Text[3]; var Calendar: Record Date; PeriodType: Enum "Analysis Period Type"; ErrorWhenNotFound: Boolean): Boolean
    var
        PeriodPageMgt: Codeunit PeriodPageManagement;
        Found: Boolean;
    begin
        Clear(PeriodPageMgt);
        Found := PeriodPageMgt.FindDate(SearchString, Calendar, PeriodType);
        if ErrorWhenNotFound and not Found then
            Error(Text002);
        exit(Found);
    end;

    procedure SetIndentation(var TextString: Text[1024]; Indentation: Integer)
    var
        Substr: Text[1024];
    begin
        Substr := PadStr(Substr, Indentation * 2, ' ');
        TextString := Substr + TextString;
    end;

    procedure GetPKRange(var RecRef: RecordRef; KeyFieldNo: Integer; RecordPosition: Text; CurrSetLength: Integer) PKRange: Text[100]
    var
        FieldRef: FieldRef;
        CurFilter: Text;
        RecCount: Integer;
    begin
        RecRef.SetPosition(RecordPosition);
        RecRef.Get(RecRef.RecordId);
        PKRange := Format(RecRef.Field(KeyFieldNo).Value);
        if CurrSetLength = 1 then
            exit(PKRange);
        RecRef.Next(CurrSetLength);
        PKRange := PKRange + '..' + Format(RecRef.Field(KeyFieldNo).Value);
        FieldRef := RecRef.Field(KeyFieldNo);
        CurFilter := FieldRef.GetFilter;
        if CurFilter = '' then
            exit(PKRange);
        FieldRef.SetFilter(PKRange);
        RecCount := RecRef.Count();
        FieldRef.SetFilter(CurFilter);
        if CurrSetLength = RecCount then
            exit(PKRange);
        exit('');
    end;

    procedure GenerateDimColumnCaption(DimensionCode: Code[20]; DimFilter: Text; SetWanted: Option; var RecordPosition: Text; FirstColumn: Text; LastColumn: Text; var CaptionSet: array[32] of Text[80]; var DimensionCodeBuffer: array[32] of Record "Dimension Code Buffer"; var NumberOfColumns: Integer; ShowColumnName: Boolean; var CaptionRange: Text)
    begin
        SetDimColumnSet(
          DimensionCode, DimFilter, SetWanted, RecordPosition, FirstColumn, LastColumn, NumberOfColumns);
        DimToCaptions(
          CaptionSet, DimensionCodeBuffer, DimensionCode,
          FirstColumn, LastColumn, NumberOfColumns, ShowColumnName, CaptionRange, DimFilter);
    end;

    local procedure AdjustPeriodWithDateFilter(DateFilter: Text; var PeriodStartDate: Date; var PeriodEndDate: Date)
    var
        Period: Record Date;
    begin
        if DateFilter <> '' then begin
            Period.SetFilter("Period End", DateFilter);
            if Period.GetRangeMax("Period End") < PeriodEndDate then
                PeriodEndDate := Period.GetRangeMax("Period End");
            Period.Reset();
            Period.SetFilter("Period Start", DateFilter);
            if Period.GetRangeMin("Period Start") > PeriodStartDate then
                PeriodStartDate := Period.GetRangeMin("Period Start");
        end;
    end;

    procedure RoundAmount(Amount: Decimal; RoundingFactor: Enum "Analysis Rounding Factor"): Decimal
    begin
        if Amount = 0 then
            exit(0);

        case RoundingFactor of
            RoundingFactor::"1":
                exit(Round(Amount, 1));
            RoundingFactor::"1000":
                exit(Round(Amount / 1000, 0.1));
            RoundingFactor::"1000000":
                exit(Round(Amount / 1000000, 0.1));
            else
                OnRoundAmountOnElse(Amount, RoundingFactor);
        end;

        exit(Amount);
    end;

    procedure FormatAmount(Value: Decimal; RoundingFactor: Enum "Analysis Rounding Factor"; AddCurrency: Boolean): Text[30]
    begin
        Value := RoundAmount(Value, RoundingFactor);

        if Value <> 0 then
            exit(Format(Value, 0, FormatRoundingFactor(RoundingFactor, AddCurrency)));
    end;

    local procedure ReadNormalDecimalFormat(AddCurrency: Boolean): Text
    var
        Currency: Record Currency;
    begin
        if not GLSetupRead then begin
            GeneralLedgerSetup.Get();
            GLSetupRead := true;
            if AddCurrency then
                GeneralLedgerSetup.TestField("Additional Reporting Currency");
        end;

        if AddCurrency and
           Currency.Get(GeneralLedgerSetup."Additional Reporting Currency")
        then
            exit(Currency."Amount Decimal Places");

        exit(GeneralLedgerSetup."Amount Decimal Places");
    end;

    procedure FormatRoundingFactor(RoundingFactor: Enum "Analysis Rounding Factor"; AddCurrency: Boolean): Text
    begin
        exit(FormatRoundingFactor(RoundingFactor, AddCurrency, Enum::"Analysis Negative Format"::"Minus Sign"));
    end;

    procedure FormatRoundingFactor(RoundingFactor: Enum "Analysis Rounding Factor"; AddCurrency: Boolean; NegativeAmountFormat: Enum "Analysis Negative Format") Result: Text
    var
        AmountDecimal: Text;
    begin
        case RoundingFactor of
            RoundingFactor::None:
                AmountDecimal := ReadNormalDecimalFormat(AddCurrency);
            RoundingFactor::"1":
                AmountDecimal := Format(0);
            RoundingFactor::"1000", RoundingFactor::"1000000":
                AmountDecimal := Format(1);
            else
                OnFormatRoundingFactorOnElse(AmountDecimal, RoundingFactor);
        end;
        case NegativeAmountFormat of
            NegativeAmountFormat::"Minus Sign":
                Result := StrSubstNo(RoundingFormatTxt, AmountDecimal, '');
            NegativeAmountFormat::"Parentheses":
                Result := StrSubstNo(RoundingFormatTxt, AmountDecimal, NegativeInParenthesesFormatTxt);
            else
                OnFormatRoundingFactorNegativeFormatOnElse(AmountDecimal, NegativeAmountFormat, Result);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCaption(var RecRef: RecordRef; CaptionFieldNo: Integer; var Caption: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGeneratePeriodAndCaption(PeriodType: Enum "Analysis Period Type"; Calendar: Record Date; var IsHandled: Boolean; UseNameForCaption: Boolean; var CurrSetLength: Integer; var CaptionSet: array[32] of Text[80]; var PeriodRecords: array[32] of Record Date temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetDimColumnSetOnAfterDimValSetFilters(DimensionCode: Code[20]; DimFilter: Text; var DimensionValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFormatRoundingFactorOnElse(var AmountDecimal: Text; RoundingFactor: Enum "Analysis Rounding Factor")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFormatRoundingFactorNegativeFormatOnElse(AmountDecimal: Text; NegativeAmountFormat: Enum "Analysis Negative Format"; var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountOnElse(var Amount: Decimal; RoundingFactor: Enum "Analysis Rounding Factor")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateMatrixDataExtendedOnBeforeValidatePreviousStep(Steps: Integer; MaximumSetLength: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGeneratePeriodMatrixDataOnBeforeAdjustPeriodWithDateFilter(DateFilter: Text; var TempPeriodRecords: array[32] of Record Date temporary; var CurrSetLength: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGeneratePeriodMatrixDataOnBeforeFindDateBasedOnStepType(SetWanted: Option; var CalendarDate: Record Date; PeriodType: Enum "Analysis Period Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatrixPageStepTypeInGenerateMatrixDataExtended(SetWanted: Option; MaximumSetLength: Integer; var RecRef: RecordRef)
    begin
    end;
}

