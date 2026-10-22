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
    procedure GetPlaceholderName(Definition: Codeunit "Test Input Json"): Text
    var
        DefinitionText: Text;
        Name: Text;
        Prefix: Text;
        TokenEnd: Integer;
    begin
        if not Definition.AsJsonToken().IsValue() then
            Error(InvalidPlaceholderDefinitionErr);
        if Definition.ElementValue().IsNull() then
            Error(InvalidPlaceholderDefinitionErr);

        DefinitionText := Definition.ElementValue().AsText();
        if not TryReadToken(DefinitionText, 1, TokenEnd, Prefix, Name) then
            Error(InvalidPlaceholderDefinitionErr);
        if (Prefix <> PlaceholderPrefixTok) or (TokenEnd <> StrLen(DefinitionText)) then
            Error(InvalidPlaceholderDefinitionErr);

        exit(Name);
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
    procedure SetPlaceholder(Name: Text; Value: Text)
    begin
        SetPlaceholderForCompany(Name, Value, CompanyName());
    end;

    /// <summary>
    /// Inserts or replaces the exact full name and company key without committing.
    /// A blank company registers a shared fallback. Values must not contain supported placeholder tokens.
    /// </summary>
    procedure SetPlaceholderForCompany(Name: Text; Value: Text; Company: Text)
    var
        TestInputPlaceholder: Record "Test Input Placeholder";
        NormalizedName: Code[250];
        NormalizedCompany: Text[30];
        EntryExists: Boolean;
    begin
        NormalizedName := NormalizeName(Name);
        NormalizedCompany := NormalizeCompany(Company);
        ValidatePlaceholderValue(Name, Value);

        TestInputPlaceholder.ReadIsolation := IsolationLevel::UpdLock;
        EntryExists := TestInputPlaceholder.Get(NormalizedName, NormalizedCompany);
        if not EntryExists then begin
            TestInputPlaceholder.Init();
            TestInputPlaceholder.Name := NormalizedName;
            TestInputPlaceholder.Company := NormalizedCompany;
        end;

        TestInputPlaceholder.SetValue(Value);
        if EntryExists then
            TestInputPlaceholder.Modify(true)
        else
            TestInputPlaceholder.Insert(true);
    end;

    /// <summary>
    /// Gets a value using its full name and the current company, then the shared-company fallback.
    /// Returns false and clears Value when no registration exists.
    /// </summary>
    procedure GetPlaceholder(Name: Text; var Value: Text): Boolean
    begin
        exit(GetPlaceholderForCompany(Name, Value, CompanyName()));
    end;

    /// <summary>
    /// Gets the exact company value before its shared fallback, using the same full name.
    /// An explicitly blank company reads only the shared row. An empty registered value is a match.
    /// Returns false and clears Value when no registration exists.
    /// </summary>
    procedure GetPlaceholderForCompany(Name: Text; var Value: Text; Company: Text): Boolean
    var
        TestInputPlaceholder: Record "Test Input Placeholder";
        NormalizedName: Code[250];
        NormalizedCompany: Text[30];
    begin
        Clear(Value);
        NormalizedName := NormalizeName(Name);
        NormalizedCompany := NormalizeCompany(Company);

        if not TestInputPlaceholder.Get(NormalizedName, NormalizedCompany) then begin
            if NormalizedCompany = '' then
                exit(false);
            if not TestInputPlaceholder.Get(NormalizedName, '') then
                exit(false);
        end;

        Value := TestInputPlaceholder.GetValue();
        exit(true);
    end;

    /// <summary>
    /// Deletes the exact full-name/current-company registration, without following shared fallback.
    /// </summary>
    procedure DeletePlaceholder(Name: Text): Boolean
    begin
        exit(DeletePlaceholderForCompany(Name, CompanyName()));
    end;

    /// <summary>
    /// Deletes only the exact key. Blank company targets the shared row, not all companies.
    /// Returns false if that key does not exist.
    /// </summary>
    procedure DeletePlaceholderForCompany(Name: Text; Company: Text): Boolean
    var
        TestInputPlaceholder: Record "Test Input Placeholder";
    begin
        if not TestInputPlaceholder.Get(NormalizeName(Name), NormalizeCompany(Company)) then
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
        Output: TextBuilder;
        Prefix: Text;
        Content: Text;
        Token: Text;
        Value: Text;
        Position: Integer;
        TokenStart: Integer;
        TokenEnd: Integer;
    begin
        Position := 1;
        if not FindNextToken(InputText, Position, TokenStart, TokenEnd, Prefix, Content) then
            exit(InputText);

        repeat
            Output.Append(CopyStr(InputText, Position, TokenStart - Position));
            Token := CopyStr(InputText, TokenStart, TokenEnd - TokenStart + 1);
            case Prefix of
                PlaceholderPrefixTok:
                    if GetPlaceholder(Content, Value) then
                        Output.Append(Value)
                    else
                        Output.Append(Token);
                DateFormulaPrefixTok:
                    Output.Append(Format(TestInputDateImpl.ResolveAsDate(Token)));
                DateTimeFormulaPrefixTok:
                    Output.Append(Format(TestInputDateImpl.ResolveAsDateTime(Token)));
            end;

            Position := TokenEnd + 1;
        until not FindNextToken(InputText, Position, TokenStart, TokenEnd, Prefix, Content);

        Output.Append(CopyStr(InputText, Position));
        exit(Output.ToText());
    end;

    #endregion

    #region Date Tokens

    procedure TryExtractDateFormula(InputText: Text; var Formula: Text): Boolean
    begin
        exit(TryExtractSingleToken(InputText, DateFormulaPrefixTok, Formula));
    end;

    procedure TryExtractDateTimeFormula(InputText: Text; var Content: Text): Boolean
    begin
        exit(TryExtractSingleToken(InputText, DateTimeFormulaPrefixTok, Content));
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

    local procedure FindNextToken(InputText: Text; Position: Integer; var TokenStart: Integer; var TokenEnd: Integer; var Prefix: Text; var Content: Text): Boolean
    begin
        while Position <= StrLen(InputText) do begin
            TokenStart := InputText.IndexOf(TokenSuffixTok, Position);
            if TokenStart = 0 then
                exit(false);

            if TryReadToken(InputText, TokenStart, TokenEnd, Prefix, Content) then
                exit(true);

            Position := TokenStart + 1;
        end;
        exit(false);
    end;

    local procedure TryReadToken(InputText: Text; TokenStart: Integer; var TokenEnd: Integer; var Prefix: Text; var Content: Text): Boolean
    begin
        if CopyStr(InputText, TokenStart, StrLen(PlaceholderPrefixTok)) = PlaceholderPrefixTok then
            Prefix := PlaceholderPrefixTok
        else
            if CopyStr(InputText, TokenStart, StrLen(DateTimeFormulaPrefixTok)) = DateTimeFormulaPrefixTok then
                Prefix := DateTimeFormulaPrefixTok
            else
                if CopyStr(InputText, TokenStart, StrLen(DateFormulaPrefixTok)) = DateFormulaPrefixTok then
                    Prefix := DateFormulaPrefixTok
                else
                    exit(false);

        if TokenStart + StrLen(Prefix) > StrLen(InputText) then
            exit(false);

        TokenEnd := InputText.IndexOf(TokenSuffixTok, TokenStart + StrLen(Prefix));
        if TokenEnd = 0 then
            exit(false);

        Content := CopyStr(InputText, TokenStart + StrLen(Prefix), TokenEnd - TokenStart - StrLen(Prefix));
        if Prefix = PlaceholderPrefixTok then
            exit(IsValidName(Content));

        exit(true);
    end;

    #endregion

    #region Validation

    local procedure NormalizeName(Name: Text): Code[250]
    var
        NormalizedName: Code[250];
    begin
        if not IsValidName(Name) then
            Error(InvalidNameErr, MaxStrLen(NormalizedName));

        NormalizedName := CopyStr(UpperCase(Name), 1, MaxStrLen(NormalizedName));
        exit(NormalizedName);
    end;

    local procedure IsValidName(Name: Text): Boolean
    var
        TestInputPlaceholder: Record "Test Input Placeholder";
    begin
        exit((Name <> '') and (StrLen(Name) <= MaxStrLen(TestInputPlaceholder.Name)) and
            (DelChr(Name, '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-') = ''));
    end;

    local procedure NormalizeCompany(Company: Text): Text[30]
    var
        TestInputPlaceholder: Record "Test Input Placeholder";
        NormalizedCompany: Text[30];
    begin
        if StrLen(Company) > MaxStrLen(NormalizedCompany) then
            Error(KeyTooLongErr, TestInputPlaceholder.FieldCaption(Company), MaxStrLen(NormalizedCompany));

        NormalizedCompany := CopyStr(Company, 1, MaxStrLen(NormalizedCompany));
        exit(NormalizedCompany);
    end;

    local procedure ValidatePlaceholderValue(Name: Text; Value: Text)
    var
        Prefix: Text;
        Content: Text;
        TokenStart: Integer;
        TokenEnd: Integer;
    begin
        if FindNextToken(Value, 1, TokenStart, TokenEnd, Prefix, Content) then
            Error(ValueContainsPlaceholderErr, Name);
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
