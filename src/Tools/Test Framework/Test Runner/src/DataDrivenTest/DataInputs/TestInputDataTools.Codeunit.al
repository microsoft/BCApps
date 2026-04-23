// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Resolves data tool placeholders embedded in test input values.
/// Supports date formulas ($DateFormula-...$) and datetime formulas ($DateTimeFormula-...$).
///
/// This codeunit is SingleInstance — cache persists within a test method run
/// and resets automatically between tests via OnBeforeTestMethodRun.
///
/// Performance: On first resolve call per test, the full JSON is scanned to
/// detect which tool types are present. Tool types not found in the JSON are
/// skipped on all subsequent resolve calls (single boolean check).
/// </summary>
codeunit 130465 "Test Input Data Tools"
{
    SingleInstance = true;

    #region Lifecycle

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure BeforeTestMethodRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var CurrentTestMethodLine: Record "Test Method Line")
    begin
        Reset();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterRunTestSuite', '', false, false)]
    local procedure AfterTestSuite()
    begin
        Reset();
    end;

    local procedure Reset()
    begin
        HasDateFormulas := false;
        HasDateTimeFormulas := false;
        CacheInitialized := false;
    end;

    #endregion

    #region Cache

    local procedure EnsureCacheInitialized()
    var
        TestInput: Codeunit "Test Input";
        FullJson: Text;
    begin
        if CacheInitialized then
            exit;

        CacheInitialized := true;
        FullJson := TestInput.GetTestInputValue();

        if FullJson = '' then
            exit;

        HasDateFormulas := FullJson.Contains(DateFormulaPrefixTok);
        HasDateTimeFormulas := FullJson.Contains(DateTimeFormulaPrefixTok);
    end;

    local procedure HasAnyTools(): Boolean
    begin
        exit(HasDateFormulas or HasDateTimeFormulas);
    end;

    #endregion

    #region Public API — Text Resolution

    /// <summary>
    /// Resolves all data tool placeholders in the text.
    /// If the full test input contains no data tools, returns the text unchanged.
    /// Handles both full-match values (entire string is one token)
    /// and embedded tokens (token appears within a larger string).
    /// </summary>
    /// <param name="InputText">The raw text value from the test input.</param>
    /// <returns>The text with all placeholders resolved.</returns>
    procedure ResolveText(InputText: Text): Text
    begin
        EnsureCacheInitialized();

        if not HasAnyTools() then
            exit(InputText);

        // Process DateTimeFormula before DateFormula (longer prefix avoids false match)
        if HasDateTimeFormulas then
            InputText := ResolveDateTimeFormulasInText(InputText);

        if HasDateFormulas then
            InputText := ResolveDateFormulasInText(InputText);

        exit(InputText);
    end;

    #endregion

    #region Public API — Typed Resolution

    /// <summary>
    /// Resolves a value to a Date.
    /// If the value is a $DateFormula-...$ placeholder, calculates the date via CalcDate relative to WorkDate.
    /// Otherwise evaluates the resolved text as a date.
    /// </summary>
    /// <param name="InputText">The raw text value.</param>
    /// <returns>The resolved Date.</returns>
    procedure ResolveAsDate(InputText: Text): Date
    var
        Formula: Text;
        ResultDate: Date;
    begin
        if TryExtractSingleToken(InputText, DateFormulaPrefixTok, Formula) then
            exit(CalcDate(Formula, WorkDate()));

        Evaluate(ResultDate, ResolveText(InputText));
        exit(ResultDate);
    end;

    /// <summary>
    /// Resolves a value to a DateTime.
    /// Supports:
    ///   $DateTimeFormula-&lt;formula&gt;$                  → date + time 0T
    ///   $DateTimeFormula-&lt;formula&gt;-HH:MM:SS$         → date + explicit time
    ///   $DateTimeFormula-&lt;formula&gt;-HH:MM:SS.FFFF$    → date + time with milliseconds
    /// </summary>
    /// <param name="InputText">The raw text value.</param>
    /// <returns>The resolved DateTime.</returns>
    procedure ResolveAsDateTime(InputText: Text): DateTime
    var
        Content: Text;
        Formula: Text;
        TimePart: Time;
        TimeText: Text;
        CloseBracketPos: Integer;
    begin
        if TryExtractSingleToken(InputText, DateTimeFormulaPrefixTok, Content) then begin
            // Content is "<formula>" or "<formula>-HH:MM:SS" or "<formula>-HH:MM:SS.FFFF"
            CloseBracketPos := Content.IndexOf('>');
            if CloseBracketPos > 0 then begin
                Formula := CopyStr(Content, 1, CloseBracketPos);
                if CloseBracketPos < StrLen(Content) then begin
                    // Skip the '-' separator after '>'
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

    #endregion

    #region Internal — Token Parsing

    /// <summary>
    /// Checks if the entire InputText is a single token with the given prefix.
    /// Token format: prefix + content + $
    /// Returns the content portion if matched.
    /// </summary>
    local procedure TryExtractSingleToken(InputText: Text; Prefix: Text; var Content: Text): Boolean
    begin
        if not InputText.StartsWith(Prefix) then
            exit(false);
        if not InputText.EndsWith(TokenSuffixTok) then
            exit(false);

        Content := CopyStr(InputText, StrLen(Prefix) + 1, StrLen(InputText) - StrLen(Prefix) - StrLen(TokenSuffixTok));
        exit(true);
    end;

    local procedure ResolveDateFormulasInText(InputText: Text): Text
    var
        Token: Text;
        Formula: Text;
        ResolvedDate: Date;
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartPos := InputText.IndexOf(DateFormulaPrefixTok);
        while StartPos > 0 do begin
            EndPos := InputText.IndexOf(TokenSuffixTok, StartPos + StrLen(DateFormulaPrefixTok));
            if EndPos = 0 then
                exit(InputText);

            Token := CopyStr(InputText, StartPos, EndPos - StartPos + 1);
            Formula := CopyStr(InputText, StartPos + StrLen(DateFormulaPrefixTok), EndPos - StartPos - StrLen(DateFormulaPrefixTok));

            ResolvedDate := CalcDate(Formula, WorkDate());
            InputText := InputText.Replace(Token, Format(ResolvedDate));

            StartPos := InputText.IndexOf(DateFormulaPrefixTok);
        end;
        exit(InputText);
    end;

    local procedure ResolveDateTimeFormulasInText(InputText: Text): Text
    var
        Token: Text;
        Content: Text;
        Formula: Text;
        TimePart: Time;
        TimeText: Text;
        CloseBracketPos: Integer;
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartPos := InputText.IndexOf(DateTimeFormulaPrefixTok);
        while StartPos > 0 do begin
            EndPos := InputText.IndexOf(TokenSuffixTok, StartPos + StrLen(DateTimeFormulaPrefixTok));
            if EndPos = 0 then
                exit(InputText);

            Token := CopyStr(InputText, StartPos, EndPos - StartPos + 1);
            Content := CopyStr(InputText, StartPos + StrLen(DateTimeFormulaPrefixTok), EndPos - StartPos - StrLen(DateTimeFormulaPrefixTok));

            TimePart := 0T;
            CloseBracketPos := Content.IndexOf('>');
            if CloseBracketPos > 0 then begin
                Formula := CopyStr(Content, 1, CloseBracketPos);
                if CloseBracketPos < StrLen(Content) then begin
                    TimeText := CopyStr(Content, CloseBracketPos + 2);
                    if TimeText <> '' then
                        Evaluate(TimePart, TimeText);
                end;
            end else
                Formula := Content;

            InputText := InputText.Replace(Token, Format(CreateDateTime(CalcDate(Formula, WorkDate()), TimePart)));

            StartPos := InputText.IndexOf(DateTimeFormulaPrefixTok);
        end;
        exit(InputText);
    end;

    #endregion

    var
        HasDateFormulas: Boolean;
        HasDateTimeFormulas: Boolean;
        CacheInitialized: Boolean;

        DateFormulaPrefixTok: Label '$DateFormula-', Locked = true;
        DateTimeFormulaPrefixTok: Label '$DateTimeFormula-', Locked = true;
        TokenSuffixTok: Label '$', Locked = true;
}
