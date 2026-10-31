// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130467 "Test Input Date Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ResolveAsDate(InputText: Text): Date
    var
        TestInputPlaceholderImpl: Codeunit "Test Input Placeholder Impl.";
        Formula: Text;
        ResultDate: Date;
    begin
        if TestInputPlaceholderImpl.TryExtractDateFormula(InputText, Formula) then
            exit(CalcDate(Formula, WorkDate()));

        Evaluate(ResultDate, TestInputPlaceholderImpl.ResolveText(InputText));
        exit(ResultDate);
    end;

    procedure ResolveAsDateTime(InputText: Text): DateTime
    var
        TestInputPlaceholderImpl: Codeunit "Test Input Placeholder Impl.";
        Content: Text;
        Formula: Text;
        TimePart: Time;
        TimeText: Text;
        CloseBracketPos: Integer;
    begin
        if TestInputPlaceholderImpl.TryExtractDateTimeFormula(InputText, Content) then begin
            CloseBracketPos := Content.IndexOf('>');
            if CloseBracketPos > 0 then begin
                Formula := CopyStr(Content, 1, CloseBracketPos);
                if CloseBracketPos < StrLen(Content) then begin
                    // Skip the '-' separator after '>'.
                    TimeText := CopyStr(Content, CloseBracketPos + 2);
                    if TimeText <> '' then
                        Evaluate(TimePart, TimeText)
                    else
                        TimePart := 0T;
                end else
                    TimePart := 0T;
            end else begin
                Formula := Content;
                TimePart := 0T;
            end;

            exit(CreateDateTime(CalcDate(Formula, WorkDate()), TimePart));
        end;

        exit(CreateDateTime(ResolveAsDate(InputText), 0T));
    end;
}
