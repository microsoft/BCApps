// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

codeunit 409 "Dimension Value-Indent"
{
    TableNo = "Dimension Value";

    trigger OnRun()
    begin
        if not
           Confirm(
             StrSubstNo(
               Text000 +
               Text001 +
               Text002 +
               Text003, Rec."Dimension Code"), true)
        then
            exit;

        RunIndent(Rec."Dimension Code");
    end;

    var
        DimVal: Record "Dimension Value";
        Window: Dialog;
        DimValCode: array[10] of Code[20];
        i: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'This function updates the indentation of all the dimension values for dimension %1. ';
#pragma warning restore AA0470
        Text001: Label 'All dimension values between a Begin-Total and the matching End-Total are indented by one level. ';
        Text002: Label 'The Totaling field for each End-Total is also updated.\\';
        Text003: Label 'Do you want to indent the dimension values?';
        Text004: Label 'Indenting Dimension Values @1@@@@@@@@@@@@@@@@@@';
#pragma warning disable AA0470
        Text005: Label 'End-Total %1 is missing a matching Begin-Total.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ArrayExceededErr: Label 'You can only indent %1 levels for dimension values of the type Begin-Total.', Comment = '%1 = A number bigger than 1';

    procedure RunIndent(DimensionCode: Code[20])
    begin
        DimVal.SetRange("Dimension Code", DimensionCode);
        Indent();
    end;

    procedure Indent()
    var
        NoOfDimVals: Integer;
        Progress: Integer;
    begin
        Window.Open(Text004);

        NoOfDimVals := DimVal.Count();
        if NoOfDimVals = 0 then
            NoOfDimVals := 1;
        if DimVal.Find('-') then
            repeat
                Progress := Progress + 1;
                Window.Update(1, 10000 * Progress div NoOfDimVals);

                if DimVal."Dimension Value Type" = DimVal."Dimension Value Type"::"End-Total" then begin
                    if i < 1 then
                        Error(
                          Text005,
                          DimVal.Code);
                    DimVal.Totaling := DimValCode[i] + '..' + DimVal.Code;
                    i := i - 1;
                end;

                DimVal.Indentation := i;
                DimVal.Modify();

                if DimVal."Dimension Value Type" = DimVal."Dimension Value Type"::"Begin-Total" then begin
                    i := i + 1;
                    if i > ArrayLen(DimValCode) then
                        Error(ArrayExceededErr, ArrayLen(DimValCode));
                    DimValCode[i] := DimVal.Code;
                end;
            until DimVal.Next() = 0;

        Window.Close();
    end;
}

