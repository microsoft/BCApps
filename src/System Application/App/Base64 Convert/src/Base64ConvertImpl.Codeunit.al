// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Text;

using System.Runtime;

codeunit 4111 "Base64 Convert Impl."
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SystemNativeBase64Converter: Codeunit "Base64Convert";

        SourceWarningLength: Integer;
        TextLengtWarningTxt: Label 'The input string length (%1) exceeds the maximum suggested length (%2) for Base64 conversion.', Locked = true;
        StreamLengtWarningTxt: Label 'The input stream length (%1) exceeds the maximum suggested length (%2) for Base64 conversion.', Locked = true;

    internal procedure EmitLengthWarning(SourceLength: Integer; tag: Text; FormatString: Text)
    begin
        if SourceWarningLength <= 0 then
            SourceWarningLength := 10485760; // 10 * 1024 * 1024 = 10 MB

        if SourceLength > SourceWarningLength then
            Session.LogMessage(tag, StrSubstNo(FormatString, SourceLength, SourceWarningLength), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'resources', 'memory');
    end;

    procedure ToBase64(String: Text): Text
    begin
        exit(this.ToBase64(String, false));
    end;

    procedure ToBase64(String: Text; InsertLineBreaks: Boolean): Text
    begin
        exit(this.ToBase64(String, InsertLineBreaks, TextEncoding::UTF8, 0));
    end;

    procedure ToBase64(String: Text; TextEncoding: TextEncoding): Text
    begin
        exit(this.ToBase64(String, false, TextEncoding, 0));
    end;

    procedure ToBase64(String: Text; TextEncoding: TextEncoding; Codepage: Integer): Text
    begin
        exit(this.ToBase64(String, false, TextEncoding, Codepage));
    end;

    procedure ToBase64(String: Text; InsertLineBreaks: Boolean; TextEncoding: TextEncoding): Text
    begin
        exit(this.ToBase64(String, InsertLineBreaks, TextEncoding, 0));
    end;

    procedure ToBase64(String: Text; InsertLineBreaks: Boolean; TextEncoding: TextEncoding; Codepage: Integer): Text
    begin
        if String = '' then
            exit('');

        this.EmitLengthWarning(StrLen(String), '0000QN7', TextLengtWarningTxt);

        exit(SystemNativeBase64Converter.ToBase64(String, InsertLineBreaks, TextEncoding, Codepage));
    end;

    procedure ToBase64(InStream: InStream): Text
    begin
        exit(this.ToBase64(InStream, false));
    end;

    procedure ToBase64(InStream: InStream; InsertLineBreaks: Boolean): Text
    begin
        if (InStream.Length < 1) or InStream.EOS then
            exit('');

        this.EmitLengthWarning(InStream.Length, '0000QN8', StreamLengtWarningTxt);
        exit(SystemNativeBase64Converter.ToBase64(InStream, InsertLineBreaks));
    end;

    procedure ToBase64(InStream: InStream; InsertLineBreaks: Boolean; OutStream: OutStream)
    begin
        if (InStream.Length < 1) or InStream.EOS then
            exit;

        this.EmitLengthWarning(InStream.Length, '0000QN9', StreamLengtWarningTxt);
        SystemNativeBase64Converter.ToBase64(InStream, InsertLineBreaks, OutStream)
    end;

    [NonDebuggable]
    procedure ToBase64(SecretString: SecretText): SecretText
    begin
        if SecretString.IsEmpty() then
            exit;
        exit(SystemNativeBase64Converter.ToBase64(SecretString.Unwrap(), false, TextEncoding::UTF8, 0));
    end;

    procedure ToBase64Url(String: Text; TextEncoding: TextEncoding; Codepage: Integer): Text
    var
        Base64String: Text;
    begin
        Base64String := ToBase64(String, false, TextEncoding, Codepage);
        exit(this.RemoveUrlUnsafeChars(Base64String));
    end;

    procedure ToBase64Url(String: Text): Text
    begin
        exit(this.ToBase64Url(String, TextEncoding::UTF8, 0));
    end;

    procedure ToBase64Url(String: Text; TextEncoding: TextEncoding): Text
    begin
        exit(ToBase64Url(String, TextEncoding, 0));
    end;

    procedure ToBase64Url(InStream: InStream): Text
    var
        Base64String: Text;
    begin
        Base64String := this.ToBase64(InStream, false);
        exit(this.RemoveUrlUnsafeChars(Base64String));
    end;

    [NonDebuggable]
    procedure ToBase64Url(SecretString: SecretText): SecretText
    var
        Base64SecretString: SecretText;
        Base64String: Text;
    begin
        Base64SecretString := this.ToBase64(SecretString);
        if Base64SecretString.IsEmpty() then
            exit;
        Base64String := Base64SecretString.Unwrap();
        exit(this.RemoveUrlUnsafeChars(Base64String));
    end;

    [NonDebuggable]
    local procedure RemoveUrlUnsafeChars(Base64String: Text): Text
    var
        TB: TextBuilder;
        Ch: Char;
    begin
        foreach Ch in Base64String do
            case Ch of
                '+':
                    TB.Append('-');
                '/':
                    TB.Append('_');
                '=':
                    continue;
                else
                    TB.Append(Ch);
            end;

        exit(TB.ToText());
    end;

    procedure FromBase64(Base64String: Text; TextEncoding: TextEncoding): Text
    begin
        exit(this.FromBase64(Base64String, TextEncoding, 1252));
    end;

    procedure FromBase64(Base64String: Text; TextEncoding: TextEncoding; CodePage: Integer): Text
    begin
        if Base64String = '' then
            exit('');

        this.EmitLengthWarning(StrLen(Base64String), '0000QNA', TextLengtWarningTxt);
        exit(this.SystemNativeBase64Converter.FromBase64(Base64String, TextEncoding, CodePage));
    end;

    procedure FromBase64(Base64String: Text): Text
    begin
        exit(this.FromBase64(Base64String, TextEncoding::UTF8, 0));
    end;

    procedure FromBase64(Base64String: Text; OutStream: OutStream)
    begin
        if Base64String <> '' then begin
            this.EmitLengthWarning(StrLen(Base64String), '0000QNB', TextLengtWarningTxt);
            this.SystemNativeBase64Converter.FromBase64(Base64String, OutStream);
        end;
    end;

    [NonDebuggable]
    procedure FromBase64(Base64SecretString: SecretText): SecretText
    begin
        if Base64SecretString.IsEmpty() then
            exit;

        exit(this.SystemNativeBase64Converter.FromBase64(Base64SecretString.Unwrap(), TextEncoding::UTF8, 0));
    end;
}
