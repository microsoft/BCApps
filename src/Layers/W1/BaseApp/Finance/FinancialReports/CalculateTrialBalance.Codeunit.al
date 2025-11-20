// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Period;
using System.Environment;

codeunit 1391 "Calculate Trial Balance"
{
    var
        DescriptionLbl: Label 'Desc', Locked = true;
        ValuesLbl: Label 'Vals', Locked = true;
        PeriodCaptionLbl: Label 'Per', Locked = true;
        NoOfColumnsLbl: Label 'NoOfColumns', Locked = true;
        TrialBalanceTelemetryCategoryTok: Label 'Trial Balance', Locked = true;
        FailedToTransformDictionaryTelemetryMsg: Label 'Failed to transform dictionary to values. Dictionary length = %1 and expected length = %2', Locked = true;

    trigger OnRun()
    var
        AccountingPeriod: Record "Accounting Period";
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        TrialBalanceCacheMgt: Codeunit "Trial Balance Cache Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        Inputs: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Descriptions: array[9] of Text[80];
        Values: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
        NoOfColumns: Integer;
        NoOfColumnsTxt: Text;
    begin
        if not TryGetInputParameters(Inputs) then begin // When the codeunit is called directly or not in the context of page background task, TryGetInputParameters will return false
            NoOfColumns := 2;

            if (ClientTypeManagement.GetCurrentClientType() = ClientType::Phone) or AccountingPeriod.IsEmpty() then
                NoOfColumns := 1;
            TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);
            TrialBalanceCacheMgt.SaveToCache(Descriptions, Values, PeriodCaptionTxt);
            exit;
        end;

        Inputs.Get(NoOfColumnsLbl, NoOfColumnsTxt);
        if not Evaluate(NoOfColumns, NoOfColumnsTxt) then
            exit;

        NoOfColumns := 2;
        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);
        TransformValuesToDictionary(Descriptions, Values, PeriodCaptionTxt, NoOfColumns, Results);

        Page.SetBackgroundTaskResult(Results);
    end;

    internal procedure TransformValuesToDictionary(Descriptions: array[9] of Text[80]; Values: array[9, 2] of Decimal; PeriodCaptionTxt: array[2] of Text; NoOfColumns: Integer; var OutDictionary: Dictionary of [Text, Text])
    var
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(Descriptions) do
            OutDictionary.Add(StrSubstNo('%1%2', DescriptionLbl, Index), Descriptions[Index]);

        for Index := 1 to ArrayLen(Values, 1) do begin
            OutDictionary.Add(StrSubstNo('%1%2%3', ValuesLbl, Index, 1), Format(Values[Index, 1]));
            OutDictionary.Add(StrSubstNo('%1%2%3', ValuesLbl, Index, 2), Format(Values[Index, 2]));
        end;

        for Index := 1 to ArrayLen(PeriodCaptionTxt) do
            OutDictionary.Add(StrSubstNo('%1%2', PeriodCaptionLbl, Index), PeriodCaptionTxt[Index]);
    end;

    internal procedure TransformDictionaryToValues(var Descriptions: array[9] of Text[80]; var Values: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text; NoOfColumns: Integer; OutDictionary: Dictionary of [Text, Text])
    var
        Index: Integer;
        DictionaryValue: Text;
    begin
        if OutDictionary.Count <> ArrayLen(Descriptions) + ArrayLen(Values) + ArrayLen(PeriodCaptionTxt) then begin
            Session.LogMessage('0000ODT', StrSubstNo(FailedToTransformDictionaryTelemetryMsg, OutDictionary.Count, ArrayLen(Descriptions) + ArrayLen(Values) + ArrayLen(PeriodCaptionTxt)), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TrialBalanceTelemetryCategoryTok);
            exit;
        end;

        for Index := 1 to ArrayLen(Descriptions) do
            if OutDictionary.Get(StrSubstNo('%1%2', DescriptionLbl, Index), DictionaryValue) then
                Descriptions[Index] := CopyStr(DictionaryValue, 1, MaxStrLen(Descriptions[Index]));

        for Index := 1 to ArrayLen(Values, 1) do begin
            if OutDictionary.Get(StrSubstNo('%1%2%3', ValuesLbl, Index, 1), DictionaryValue) then
                if Evaluate(Values[Index, 1], DictionaryValue) then;

            if OutDictionary.Get(StrSubstNo('%1%2%3', ValuesLbl, Index, 2), DictionaryValue) then
                if Evaluate(Values[Index, 2], DictionaryValue) then;
        end;

        for Index := 1 to ArrayLen(PeriodCaptionTxt) do
            if OutDictionary.Get(StrSubstNo('%1%2', PeriodCaptionLbl, Index), DictionaryValue) then
                PeriodCaptionTxt[Index] := CopyStr(DictionaryValue, 1, MaxStrLen(PeriodCaptionTxt[Index]));
    end;

    [TryFunction]
    local procedure TryGetInputParameters(var Inputs: Dictionary of [Text, Text])
    begin
        Inputs := Page.GetBackgroundParameters();
    end;

    internal procedure GetDescriptionLabel(): Text
    begin
        exit(DescriptionLbl);
    end;

    internal procedure GetValuesLabel(): Text
    begin
        exit(ValuesLbl);
    end;

    internal procedure GetPeriodCaptionLabel(): Text
    begin
        exit(PeriodCaptionLbl);
    end;

    internal procedure GetNoOfColumnsLabel(): Text
    begin
        exit(NoOfColumnsLbl);
    end;
}