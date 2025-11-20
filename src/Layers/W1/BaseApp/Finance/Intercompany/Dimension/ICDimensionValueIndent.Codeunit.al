// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

codeunit 429 "IC Dimension Value-Indent"
{
    TableNo = "IC Dimension Value";

    trigger OnRun()
    begin
        if not Confirm(StrSubstNo(ICDimValueIndentQst, Rec."Dimension Code"), true) then
            exit;
        ICDimesionValue.SetRange("Dimension Code", Rec."Dimension Code");
        Indent();
    end;

    var
        ICDimesionValue: Record "IC Dimension Value";
        Window: Dialog;

#pragma warning disable AA0074
        Text004: Label 'Indenting IC Dimension Values @1@@@@@@@@@@@@@@@@@@';
#pragma warning restore AA0074
        EndTotalWithOutBeginTotalErr: Label 'End-Total %1 is missing a matching Begin-Total.', Comment = '%1 = IC Dim Value code';
        ICDimValueIndentQst: Label 'This function updates the indentation of all the IC dimension values for IC dimension %1. All IC dimension values between a Begin-Total and the matching End-Total are indented by one level. The Totaling field for each End-Total is also updated.\\Do you want to indent the IC dimension values?', Comment = '%1 - field value';

    local procedure Indent()
    var
        NoOfDimVals: Integer;
        Progress: Integer;
        CurrentIndentLevel: Integer;
    begin
        Window.Open(Text004);

        NoOfDimVals := ICDimesionValue.Count();
        if NoOfDimVals = 0 then
            NoOfDimVals := 1;
        if not ICDimesionValue.IsEmpty() then begin
            ICDimesionValue.FindSet();
            CurrentIndentLevel := 0;
            repeat
                Progress := Progress + 1;
                Window.Update(1, 10000 * Progress div NoOfDimVals);
                if ICDimesionValue."Dimension Value Type" = ICDimesionValue."Dimension Value Type"::"End-Total" then begin
                    if CurrentIndentLevel < 1 then
                        Error(EndTotalWithOutBeginTotalErr, ICDimesionValue.Code);
                    CurrentIndentLevel := CurrentIndentLevel - 1;
                end;

                ICDimesionValue.Indentation := CurrentIndentLevel;
                ICDimesionValue.Modify();

                if ICDimesionValue."Dimension Value Type" = ICDimesionValue."Dimension Value Type"::"Begin-Total" then
                    CurrentIndentLevel += 1;
            until ICDimesionValue.Next() = 0;
        end;
        Window.Close();
    end;
}

