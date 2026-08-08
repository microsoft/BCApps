// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

#if not CLEAN29
using Microsoft.eServices.EDocument;
#endif
using System.Reflection;

codeunit 13925 "Library - E-Doc DE"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        DefaultCoarseRoutingTxt: Label '99', Locked = true;
        CapturedEDocumentServiceCode: Code[20];
        EDocumentServiceEventCount: Integer;

    /// <summary>
    /// Resets the OnAfterFindEDocumentService capture state. Bind this codeunit with
    /// BindSubscription before the export and unbind afterwards.
    /// </summary>
    procedure ClearCapturedEDocumentService()
    begin
        Clear(CapturedEDocumentServiceCode);
        Clear(EDocumentServiceEventCount);
    end;

    /// <summary>
    /// Returns the Code of the E-Document Service carried by the last OnAfterFindEDocumentService event.
    /// </summary>
    procedure GetCapturedEDocumentServiceCode(): Code[20]
    begin
        exit(CapturedEDocumentServiceCode);
    end;

    /// <summary>
    /// Returns how many times OnAfterFindEDocumentService was raised while bound.
    /// </summary>
    procedure GetEDocumentServiceEventCount(): Integer
    begin
        exit(EDocumentServiceEventCount);
    end;

#if not CLEAN29
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export XRechnung Document", 'OnAfterFindEDocumentService', '', false, false)]
    local procedure CaptureXRechnungOnAfterFindEDocumentService(var EDocumentService: Record "E-Document Service"; EDocumentFormat: Code[20])
    begin
        CapturedEDocumentServiceCode := EDocumentService.Code;
        EDocumentServiceEventCount += 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export ZUGFeRD Document", 'OnAfterFindEDocumentService', '', false, false)]
    local procedure CaptureZUGFeRDOnAfterFindEDocumentService(var EDocumentService: Record "E-Document Service")
    begin
        CapturedEDocumentServiceCode := EDocumentService.Code;
        EDocumentServiceEventCount += 1;
    end;
#pragma warning restore AL0432
#endif

    procedure CreateValidRoutingNo(): Text[50]
    var
        FineRouting: Text[20];
        CheckDigit: Text[2];
    begin
        FineRouting := GenerateAlphanumFineRouting();
        CheckDigit := ComputeCheckDigit(DefaultCoarseRoutingTxt, FineRouting);
        exit(CopyStr(DefaultCoarseRoutingTxt + '-' + FineRouting + '-' + CheckDigit, 1, 50));
    end;

    local procedure GenerateAlphanumFineRouting(): Text[20]
    begin
        // CreateGuid() produces hex chars (0-9, A-F) which are valid alphanumeric fine routing characters
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{-}'), 1, 20));
    end;

    local procedure ComputeCheckDigit(CoarseRouting: Text; FineRouting: Text): Text[2]
    var
        NumericString: Text;
        Remainder: Integer;
        CheckDigitValue: Integer;
    begin
        NumericString := ConvertToNumericString(CoarseRouting + FineRouting) + '00';
        Remainder := ComputeMod97(NumericString);
        CheckDigitValue := 98 - Remainder;
        if CheckDigitValue < 10 then
            exit(CopyStr('0' + Format(CheckDigitValue), 1, 2));
        exit(CopyStr(Format(CheckDigitValue), 1, 2));
    end;

    local procedure ConvertToNumericString(Input: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        UpperInput: Text;
        Result: Text;
        Ch: Char;
        i: Integer;
    begin
        UpperInput := UpperCase(Input);
        for i := 1 to StrLen(UpperInput) do begin
            Ch := UpperInput[i];
            if TypeHelper.IsLatinLetter(Ch) then
                Result += Format(Ch - 55)
            else
                Result += Format(Ch - 48);
        end;
        exit(Result);
    end;

    local procedure ComputeMod97(NumericString: Text): Integer
    var
        Remainder: Integer;
        DigitValue: Integer;
        i: Integer;
    begin
        Remainder := 0;
        for i := 1 to StrLen(NumericString) do begin
            Evaluate(DigitValue, CopyStr(NumericString, i, 1));
            Remainder := (Remainder * 10 + DigitValue) mod 97;
        end;
        exit(Remainder);
    end;
}
