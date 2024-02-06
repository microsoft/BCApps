// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

codeunit 1282 "Password Handler Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        InsufficientPassLengthErr: Label 'The password must contain at least %1 characters.', Comment = '%1 = the number of characters';

#if not CLEAN24
    [Obsolete('Replaced by GenerateSecretPassword with SecretText data type.', '24.0')]
    [NonDebuggable]
    procedure GeneratePassword(): Text;
    begin
#pragma warning disable AL0432
        exit(GeneratePassword(GetPasswordMinLength()));
#pragma warning restore AL0432
    end;

    [Obsolete('Replaced by GenerateSecretPassword with SecretText data type.', '24.0')]
    [NonDebuggable]
    procedure GeneratePassword(Length: Integer): Text;
    var
        PasswordGenerator: DotNet "PasswordGenerator";
        Password: Text;
        MinNumOfNonAlphanumericChars: Integer;
    begin
        if Length < GetPasswordMinLength() then
            Error(InsufficientPassLengthErr, GetPasswordMinLength());

        MinNumOfNonAlphanumericChars := 1;
        repeat
            Password := PasswordGenerator.GeneratePassword(Length, MinNumOfNonAlphanumericChars);
        until IsPasswordStrong(Password);
        exit(Password);
    end;
#endif

    procedure GenerateSecretPassword(): SecretText;
    begin
        exit(GenerateSecretPassword(GetPasswordMinLength()));
    end;

    procedure GenerateSecretPassword(Length: Integer) Password: SecretText;
    var
        PasswordGenerator: DotNet "PasswordGenerator";
        MinNumOfNonAlphanumericChars: Integer;
    begin
        if Length < GetPasswordMinLength() then
            Error(InsufficientPassLengthErr, GetPasswordMinLength());

        MinNumOfNonAlphanumericChars := 1;
        repeat
            Password := PasswordGenerator.GeneratePassword(Length, MinNumOfNonAlphanumericChars);
        until IsPasswordStrong(Password);
        exit(Password);
    end;

    [NonDebuggable]
    procedure IsPasswordStrong(Password: SecretText): Boolean;
    var
        CharacterSets: List of [Text];
        CharacterSet: Text;
        Counter: Integer;
        SequenceLength: Integer;
        PasswordPlain: Text;
    begin
        PasswordPlain := Password.Unwrap();
        if StrLen(PasswordPlain) < GetPasswordMinLength() then
            exit(false);

        AddRequiredCharacterSets(CharacterSets);

        // Check all character sets are present
        for Counter := 1 to CharacterSets.Count() do begin
            CharacterSets.Get(Counter, CharacterSet);
            if not ContainsAny(PasswordPlain, CharacterSet) then
                exit(false);
        end;

        // Check no sequences
        SequenceLength := 3;
        AddReversedCharacterSets(CharacterSets);
        for Counter := 1 to StrLen(PasswordPlain) - SequenceLength + 1 do
            if AreCharacterValuesEqualOrSequential(CharacterSets, CopyStr(PasswordPlain, Counter, SequenceLength)) then
                exit(false);

        exit(true);
    end;

    procedure GetPasswordMinLength(): Integer
    var
        PasswordDialogManagement: Codeunit "Password Dialog Management";
        MinPasswordLength: Integer;
    begin
        PasswordDialogManagement.OnSetMinPasswordLength(MinPasswordLength);
        if MinPasswordLength < 8 then
            MinPasswordLength := 8; // the default

        exit(MinPasswordLength);
    end;

    [NonDebuggable]
    local procedure ContainsAny(String: Text; Characters: Text): Boolean;
    var
        ReplacedText: Text;
    begin
        ReplacedText := DelChr(String, '=', Characters);
        if StrLen(ReplacedText) < StrLen(String) then
            exit(true);
        exit(false);
    end;

    [NonDebuggable]
    local procedure AreCharacterValuesEqualOrSequential(CharacterSets: List of [Text]; SeqLetters: Text): Boolean;
    var
        CharacterSet: Text;
        ReplacedText: Text;
        Counter: Integer;
    begin
        // Check if all the characters are the same
        ReplacedText := DelChr(SeqLetters, '=', SeqLetters[1]);
        if StrLen(ReplacedText) = 0 then
            exit(true);

        // Check if characters form a sequence
        for Counter := 1 to CharacterSets.Count() do begin
            CharacterSets.Get(Counter, CharacterSet);
            if (StrPos(CharacterSet, SeqLetters) > 0) then
                exit(true);
        end;

        exit(false);
    end;

    local procedure AddRequiredCharacterSets(var CharacterSets: List of [Text])
    var
        UppercaseCharacters: Text;
        Digits: Text;
        SpecialCharacters: Text;
    begin
        UppercaseCharacters := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        Digits := '0123456789';
        SpecialCharacters := '!@#$%^&*()_-+=[{]};:<>|./?';

        CharacterSets.Add(UppercaseCharacters);
        CharacterSets.Add(LowerCase(UppercaseCharacters));
        CharacterSets.Add(Digits);
        CharacterSets.Add(SpecialCharacters);
    end;

    local procedure AddReversedCharacterSets(var CharacterSets: List of [Text])
    var
        ReverseUppercaseCharacters: Text;
        ReverseDigits: Text;
    begin
        ReverseUppercaseCharacters := 'ZYXWVUTSRQPONMLKJIHGFEDCBA';
        ReverseDigits := '9876543210';

        CharacterSets.Add(ReverseUppercaseCharacters);
        CharacterSets.Add(LowerCase(ReverseUppercaseCharacters));
        CharacterSets.Add(ReverseDigits);
    end;
}

