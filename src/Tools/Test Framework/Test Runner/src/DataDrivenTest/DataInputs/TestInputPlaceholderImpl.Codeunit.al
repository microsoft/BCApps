// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130466 "Test Input Placeholder Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    #region Placeholder Definitions

    /// <summary>
    /// Gets the bare name from a single, valid named-placeholder definition.
    /// Reads the raw scalar without resolving an existing registration.
    /// Raises an error if the definition is not a complete named token with a valid name.
    /// </summary>
    procedure GetPlaceholderName(PlaceholderDefinition: Codeunit "Test Input Json"): Text
    var
        PlaceholderDefinitionText: Text;
        PlaceholderName: Text;
        TokenPrefix: Text;
        TokenEndPosition: Integer;
    begin
        if not PlaceholderDefinition.AsJsonToken().IsValue() then
            Error(InvalidPlaceholderDefinitionErr);
        if PlaceholderDefinition.ElementValue().IsNull() then
            Error(InvalidPlaceholderDefinitionErr);

        PlaceholderDefinitionText := PlaceholderDefinition.ElementValue().AsText();
        if not TryReadToken(PlaceholderDefinitionText, 1, TokenEndPosition, TokenPrefix, PlaceholderName) then
            Error(InvalidPlaceholderDefinitionErr);
        if (TokenPrefix <> PlaceholderPrefixTok) or (TokenEndPosition <> StrLen(PlaceholderDefinitionText)) then
            Error(InvalidPlaceholderDefinitionErr);

        exit(PlaceholderName);
    end;

    /// <summary>
    /// Reports whether text contains the named-placeholder marker, including incomplete references.
    /// Does not resolve text or look up registrations.
    /// </summary>
    procedure ContainsNamedPlaceholderMarker(InputText: Text): Boolean
    begin
        exit(InputText.Contains(PlaceholderPrefixTok));
    end;

    #endregion

    #region Placeholder Values

    /// <summary>
    /// Inserts or replaces a value using its full name and the current company.
    /// </summary>
    procedure SetPlaceholder(PlaceholderName: Text; PlaceholderValue: Text)
    begin
        this.SetPlaceholderForCompany(PlaceholderName, PlaceholderValue, CompanyName());
    end;

    /// <summary>
    /// Inserts or replaces the exact full name and company key without committing.
    /// A blank company registers a shared fallback. Values must not contain supported placeholder tokens.
    /// </summary>
    procedure SetPlaceholderForCompany(PlaceholderName: Text; PlaceholderValue: Text; PlaceholderCompany: Text)
    var
        TestInputPlaceholder: Record "Test Input Placeholder";
        NormalizedPlaceholderName: Code[250];
        NormalizedPlaceholderCompany: Text[30];
        PlaceholderExists: Boolean;
    begin
        NormalizedPlaceholderName := NormalizeName(PlaceholderName);
        NormalizedPlaceholderCompany := NormalizeCompany(PlaceholderCompany);
        ValidatePlaceholderValue(PlaceholderName, PlaceholderValue);

        TestInputPlaceholder.ReadIsolation := IsolationLevel::UpdLock;
        PlaceholderExists := TestInputPlaceholder.Get(NormalizedPlaceholderName, NormalizedPlaceholderCompany);
        if not PlaceholderExists then begin
            Clear(TestInputPlaceholder);
            TestInputPlaceholder.Name := NormalizedPlaceholderName;
            TestInputPlaceholder.Company := NormalizedPlaceholderCompany;
        end;

        TestInputPlaceholder.SetValue(PlaceholderValue);
        if PlaceholderExists then
            TestInputPlaceholder.Modify(true)
        else
            TestInputPlaceholder.Insert(true);
    end;

    /// <summary>
    /// Gets a value using its full name and the current company, then the shared-company fallback.
    /// Returns false and clears PlaceholderValue when no registration exists.
    /// </summary>
    procedure GetPlaceholder(PlaceholderName: Text; var PlaceholderValue: Text): Boolean
    begin
        exit(GetPlaceholderForCompany(PlaceholderName, PlaceholderValue, CompanyName()));
    end;

    /// <summary>
    /// Gets the exact company value before its shared fallback, using the same full name.
    /// An explicitly blank company reads only the shared row. An empty registered value is a match.
    /// Returns false and clears PlaceholderValue when no registration exists.
    /// </summary>
    procedure GetPlaceholderForCompany(PlaceholderName: Text; var PlaceholderValue: Text; PlaceholderCompany: Text): Boolean
    var
        TestInputPlaceholder: Record "Test Input Placeholder";
        NormalizedPlaceholderName: Code[250];
        NormalizedPlaceholderCompany: Text[30];
    begin
        Clear(PlaceholderValue);
        NormalizedPlaceholderName := NormalizeName(PlaceholderName);
        NormalizedPlaceholderCompany := NormalizeCompany(PlaceholderCompany);

        if not TestInputPlaceholder.Get(NormalizedPlaceholderName, NormalizedPlaceholderCompany) then begin
            if NormalizedPlaceholderCompany = '' then
                exit(false);
            if not TestInputPlaceholder.Get(NormalizedPlaceholderName, '') then
                exit(false);
        end;

        PlaceholderValue := TestInputPlaceholder.GetValue();
        exit(true);
    end;

    /// <summary>
    /// Deletes the exact full-name/current-company registration, without following shared fallback.
    /// </summary>
    procedure DeletePlaceholder(PlaceholderName: Text): Boolean
    begin
        exit(DeletePlaceholderForCompany(PlaceholderName, CompanyName()));
    end;

    /// <summary>
    /// Deletes only the exact key. Blank company targets the shared row, not all companies.
    /// Returns false if that key does not exist.
    /// </summary>
    procedure DeletePlaceholderForCompany(PlaceholderName: Text; PlaceholderCompany: Text): Boolean
    var
        TestInputPlaceholder: Record "Test Input Placeholder";
    begin
        if not TestInputPlaceholder.Get(NormalizeName(PlaceholderName), NormalizeCompany(PlaceholderCompany)) then
            exit(false);

        TestInputPlaceholder.Delete(true);
        exit(true);
    end;

    /// <summary>
    /// Deletes every placeholder registration across all names and companies without committing.
    /// </summary>
    procedure DeleteAllPlaceholders()
    var
        TestInputPlaceholder: Record "Test Input Placeholder";
    begin
        TestInputPlaceholder.DeleteAll(true);
    end;

    #endregion

    #region Text Resolution

    /// <summary>
    /// Resolves named, date, and datetime tokens on every call.
    /// Named tokens use their full name and the current company. Unknown names remain unchanged.
    /// Only the original input is scanned; replacement text is never scanned again.
    /// </summary>
    /// <param name="InputText">The raw text value from the test input.</param>
    /// <returns>The text with known placeholders resolved.</returns>
    procedure ResolveText(InputText: Text): Text
    var
        TestInputDateImpl: Codeunit "Test Input Date Impl.";
        ResolvedTextBuilder: TextBuilder;
        TokenPrefix: Text;
        TokenContent: Text;
        TokenText: Text;
        PlaceholderValue: Text;
        SearchPosition: Integer;
        TokenStartPosition: Integer;
        TokenEndPosition: Integer;
    begin
        SearchPosition := 1;
        if not FindNextToken(InputText, SearchPosition, TokenStartPosition, TokenEndPosition, TokenPrefix, TokenContent) then
            exit(InputText);

        repeat
            ResolvedTextBuilder.Append(CopyStr(InputText, SearchPosition, TokenStartPosition - SearchPosition));
            TokenText := CopyStr(InputText, TokenStartPosition, TokenEndPosition - TokenStartPosition + 1);
            case TokenPrefix of
                PlaceholderPrefixTok:
                    if GetPlaceholder(TokenContent, PlaceholderValue) then
                        ResolvedTextBuilder.Append(PlaceholderValue)
                    else
                        ResolvedTextBuilder.Append(TokenText);
                DateFormulaPrefixTok:
                    ResolvedTextBuilder.Append(Format(TestInputDateImpl.ResolveAsDate(TokenText)));
                DateTimeFormulaPrefixTok:
                    ResolvedTextBuilder.Append(Format(TestInputDateImpl.ResolveAsDateTime(TokenText)));
            end;

            SearchPosition := TokenEndPosition + 1;
        until not FindNextToken(InputText, SearchPosition, TokenStartPosition, TokenEndPosition, TokenPrefix, TokenContent);

        ResolvedTextBuilder.Append(CopyStr(InputText, SearchPosition));
        exit(ResolvedTextBuilder.ToText());
    end;

    #endregion

    #region Date Tokens

    procedure TryExtractDateFormula(InputText: Text; var DateFormulaText: Text): Boolean
    begin
        exit(TryExtractSingleToken(InputText, DateFormulaPrefixTok, DateFormulaText));
    end;

    procedure TryExtractDateTimeFormula(InputText: Text; var DateTimeFormulaText: Text): Boolean
    begin
        exit(TryExtractSingleToken(InputText, DateTimeFormulaPrefixTok, DateTimeFormulaText));
    end;

    #endregion

    #region Internal — Token Parsing

    /// <summary>
    /// Checks if the entire InputText is a single token with the given prefix.
    /// Token format: prefix + content + $
    /// Returns the content portion if matched.
    /// </summary>
    local procedure TryExtractSingleToken(InputText: Text; TokenPrefix: Text; var TokenContent: Text): Boolean
    begin
        if not InputText.StartsWith(TokenPrefix) then
            exit(false);
        if not InputText.EndsWith(TokenSuffixTok) then
            exit(false);

        TokenContent := CopyStr(InputText, StrLen(TokenPrefix) + 1, StrLen(InputText) - StrLen(TokenPrefix) - StrLen(TokenSuffixTok));
        exit(true);
    end;

    local procedure FindNextToken(InputText: Text; SearchPosition: Integer; var TokenStartPosition: Integer; var TokenEndPosition: Integer; var TokenPrefix: Text; var TokenContent: Text): Boolean
    begin
        while SearchPosition <= StrLen(InputText) do begin
            TokenStartPosition := InputText.IndexOf(TokenSuffixTok, SearchPosition);
            if TokenStartPosition = 0 then
                exit(false);

            if TryReadToken(InputText, TokenStartPosition, TokenEndPosition, TokenPrefix, TokenContent) then
                exit(true);

            SearchPosition := TokenStartPosition + 1;
        end;
        exit(false);
    end;

    local procedure TryReadToken(InputText: Text; TokenStartPosition: Integer; var TokenEndPosition: Integer; var TokenPrefix: Text; var TokenContent: Text): Boolean
    begin
        if CopyStr(InputText, TokenStartPosition, StrLen(PlaceholderPrefixTok)) = PlaceholderPrefixTok then
            TokenPrefix := PlaceholderPrefixTok
        else
            if CopyStr(InputText, TokenStartPosition, StrLen(DateTimeFormulaPrefixTok)) = DateTimeFormulaPrefixTok then
                TokenPrefix := DateTimeFormulaPrefixTok
            else
                if CopyStr(InputText, TokenStartPosition, StrLen(DateFormulaPrefixTok)) = DateFormulaPrefixTok then
                    TokenPrefix := DateFormulaPrefixTok
                else
                    exit(false);

        if TokenStartPosition + StrLen(TokenPrefix) > StrLen(InputText) then
            exit(false);

        TokenEndPosition := InputText.IndexOf(TokenSuffixTok, TokenStartPosition + StrLen(TokenPrefix));
        if TokenEndPosition = 0 then
            exit(false);

        TokenContent := CopyStr(InputText, TokenStartPosition + StrLen(TokenPrefix), TokenEndPosition - TokenStartPosition - StrLen(TokenPrefix));
        if TokenPrefix = PlaceholderPrefixTok then
            exit(IsValidName(TokenContent));

        exit(true);
    end;

    #endregion

    #region Validation

    local procedure NormalizeName(PlaceholderName: Text): Code[250]
    var
        NormalizedPlaceholderName: Code[250];
    begin
        if not IsValidName(PlaceholderName) then
            Error(InvalidNameErr, MaxStrLen(NormalizedPlaceholderName));

        NormalizedPlaceholderName := CopyStr(UpperCase(PlaceholderName), 1, MaxStrLen(NormalizedPlaceholderName));
        exit(NormalizedPlaceholderName);
    end;

    local procedure IsValidName(PlaceholderName: Text): Boolean
    var
        TestInputPlaceholder: Record "Test Input Placeholder";
    begin
        exit((PlaceholderName <> '') and (StrLen(PlaceholderName) <= MaxStrLen(TestInputPlaceholder.Name)) and
            (DelChr(PlaceholderName, '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-') = ''));
    end;

    local procedure NormalizeCompany(PlaceholderCompany: Text): Text[30]
    var
        TestInputPlaceholder: Record "Test Input Placeholder";
        NormalizedPlaceholderCompany: Text[30];
    begin
        if StrLen(PlaceholderCompany) > MaxStrLen(NormalizedPlaceholderCompany) then
            Error(KeyTooLongErr, TestInputPlaceholder.FieldCaption(Company), MaxStrLen(NormalizedPlaceholderCompany));

        NormalizedPlaceholderCompany := CopyStr(PlaceholderCompany, 1, MaxStrLen(NormalizedPlaceholderCompany));
        exit(NormalizedPlaceholderCompany);
    end;

    local procedure ValidatePlaceholderValue(PlaceholderName: Text; PlaceholderValue: Text)
    var
        TokenPrefix: Text;
        TokenContent: Text;
        TokenStartPosition: Integer;
        TokenEndPosition: Integer;
    begin
        if FindNextToken(PlaceholderValue, 1, TokenStartPosition, TokenEndPosition, TokenPrefix, TokenContent) then
            Error(ValueContainsPlaceholderErr, PlaceholderName);
    end;

    #endregion

    var
        PlaceholderPrefixTok: Label '$Placeholder-', Locked = true;
        DateFormulaPrefixTok: Label '$DateFormula-', Locked = true;
        DateTimeFormulaPrefixTok: Label '$DateTimeFormula-', Locked = true;
        TokenSuffixTok: Label '$', Locked = true;
        InvalidPlaceholderDefinitionErr: Label 'The placeholder definition must be a single token in the format $Placeholder-Name$ with a valid name.', Comment = 'Do not translate $Placeholder-Name$.';
        InvalidNameErr: Label 'The placeholder name must contain between 1 and %1 characters using only letters, digits, underscores, or hyphens.', Comment = '%1 = Maximum name length';
        KeyTooLongErr: Label 'The placeholder %1 must not exceed %2 characters.', Comment = '%1 = Key field caption, %2 = Maximum length';
        ValueContainsPlaceholderErr: Label 'The value of placeholder %1 must not contain placeholder tokens.', Comment = '%1 = Placeholder name';
}
