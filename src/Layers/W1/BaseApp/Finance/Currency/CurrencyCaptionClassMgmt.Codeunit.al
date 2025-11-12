// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;

codeunit 342 "Currency CaptionClass Mgmt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        DefaultTxt: Label 'LCY';
        DefaultLongTxt: Label 'Local Currency';
        GLSetupRead: Boolean;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure ResolveCaptionClass(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionArea = '101' then
            Caption := CurCaptionClassTranslate(CaptionExpr, Resolved);
    end;

    local procedure CurCaptionClassTranslate(CaptionExpr: Text; var Resolved: Boolean): Text
    var
        Currency: Record Currency;
        CurrencyResult: Text[30];
        CommaPosition: Integer;
        CurCaptionType: Text[30];
        CurCaptionRef: Text;
    begin
        // CurCaptionType
        // <DataType>   := [String]
        // <DataValue>  :=
        // '0' -> Currency Result := Local Currency Code
        // '1' -> Currency Result := Local Currency Description
        // '2' -> Currency Result := Additional Reporting Currency Code
        // '3' -> Currency Result := Additional Reporting Currency Description

        // CurCaptionRef
        // <DataType>   := [SubString]
        // <DataValue>  := [String]
        // This string is the actual string making up the Caption.
        // It will contain a '%1', and the Currency Result will substitute for it.

        Resolved := false;
        CommaPosition := StrPos(CaptionExpr, ',');
        if CommaPosition > 0 then begin
            CurCaptionType := CopyStr(CaptionExpr, 1, CommaPosition - 1);
            CurCaptionRef := CopyStr(CaptionExpr, CommaPosition + 1);
            if not GLSetupRead then begin
                if not GLSetup.Get() then
                    exit(CurCaptionRef);
                GLSetupRead := true;
            end;
            case CurCaptionType of
                '0', '1':
                    begin
                        if GLSetup."LCY Code" = '' then
                            if CurCaptionType = '0' then
                                CurrencyResult := DefaultTxt
                            else
                                CurrencyResult := DefaultLongTxt
                        else
                            if not Currency.Get(GLSetup."LCY Code") then
                                CurrencyResult := GLSetup."LCY Code"
                            else
                                if CurCaptionType = '0' then
                                    CurrencyResult := Currency.Code
                                else
                                    CurrencyResult := Currency.Description;
                        Resolved := true;
                        exit(CopyStr(StrSubstNo(CurCaptionRef, CurrencyResult), 1, MaxStrLen(CurCaptionRef)));
                    end;
                '2', '3':
                    begin
                        if GLSetup."Additional Reporting Currency" = '' then
                            exit(CurCaptionRef);
                        if not Currency.Get(GLSetup."Additional Reporting Currency") then
                            CurrencyResult := GLSetup."Additional Reporting Currency"
                        else
                            if CurCaptionType = '2' then
                                CurrencyResult := Currency.Code
                            else
                                CurrencyResult := Currency.Description;
                        Resolved := true;
                        exit(CopyStr(StrSubstNo(CurCaptionRef, CurrencyResult), 1, MaxStrLen(CurCaptionRef)));
                    end;
                else
                    exit(CurCaptionRef);
            end;
        end;
        exit(CaptionExpr);
    end;
}

