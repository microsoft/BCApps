// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;

codeunit 343 "Dimension CaptionClass Mgmt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLSetupRead: Boolean;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure ResolveCaptionClass(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionArea = '1' then
            Caption := DimCaptionClassTranslate(Language, CaptionExpr, Resolved);
    end;

    local procedure DimCaptionClassTranslate(Language: Integer; CaptionExpr: Text; var Resolved: Boolean) Result: Text
    var
        Dim: Record Dimension;
        DimCaptionType: Text[80];
        DimCaptionRef: Text[80];
        DimOptionalParam1: Text[80];
        DimOptionalParam2: Text[80];
        CommaPosition: Integer;
        IsHandled: Boolean;
    begin
        // DIMCAPTIONTYPE
        // <DataType>   := [SubString]
        // <Length>     <= 10
        // <DataValue>  := 1..6
        // 1 to retrieve Code Caption of Global Dimension
        // 2 to retrieve Code Caption of Shortcut Dimension
        // 3 to retrieve Filter Caption of Global Dimension
        // 4 to retrieve Filter Caption of Shortcut Dimension
        // 5 to retrieve Code Caption of any kind of Dimensions
        // 6 to retrieve Filter Caption of any kind of Dimensions
        // 7 to retrieve Name Caption of Shortcut Dimension

        // DIMCAPTIONREF
        // <DataType>   := [SubString]
        // <Length>     <= 10
        // <DataValue>  :=
        // if (<DIMCAPTIONTYPE> = 1) 1..2,<DIMOPTIONALPARAM1>,<DIMOPTIONALPARAM2>
        // if (<DIMCAPTIONTYPE> = 2) 1..8,<DIMOPTIONALPARAM1>,<DIMOPTIONALPARAM2>
        // if (<DIMCAPTIONTYPE> = 3) 1..2,<DIMOPTIONALPARAM1>,<DIMOPTIONALPARAM2>
        // if (<DIMCAPTIONTYPE> = 4) 1..8,<DIMOPTIONALPARAM1>,<DIMOPTIONALPARAM2>
        // if (<DIMCAPTIONTYPE> = 5) [Table]Dimension.[Field]Code,<DIMOPTIONALPARAM1>,<DIMOPTIONALPARAM2>
        // if (<DIMCAPTIONTYPE> = 6) [Table]Dimension.[Field]Code,<DIMOPTIONALPARAM1>,<DIMOPTIONALPARAM2>
        // if (<DIMCAPTIONTYPE> = 7) 1..8,<DIMOPTIONALPARAM1>,<DIMOPTIONALPARAM2>

        // DIMOPTIONALPARAM1
        // <DataType>   := [SubString]
        // <Length>     <= 30
        // <DataValue>  := [String]
        // a string added before the dimension name

        // DIMOPTIONALPARAM2
        // <DataType>   := [SubString]
        // <Length>     <= 30
        // <DataValue>  := [String]
        // a string added after the dimension name

        Resolved := false;
        if not GetGLSetup() then
            exit('');

        CommaPosition := StrPos(CaptionExpr, ',');
        if CommaPosition > 0 then begin
            Resolved := true;
            DimCaptionType := CopyStr(CaptionExpr, 1, CommaPosition - 1);
            DimCaptionRef := CopyStr(CaptionExpr, CommaPosition + 1);
            CommaPosition := StrPos(DimCaptionRef, ',');
            if CommaPosition > 0 then begin
                DimOptionalParam1 := CopyStr(DimCaptionRef, CommaPosition + 1);
                DimCaptionRef := CopyStr(DimCaptionRef, 1, CommaPosition - 1);
                CommaPosition := StrPos(DimOptionalParam1, ',');
                if CommaPosition > 0 then begin
                    DimOptionalParam2 := CopyStr(DimOptionalParam1, CommaPosition + 1);
                    DimOptionalParam1 := CopyStr(DimOptionalParam1, 1, CommaPosition - 1);
                end else
                    DimOptionalParam2 := '';
            end else begin
                DimOptionalParam1 := '';
                DimOptionalParam2 := '';
            end;
            case DimCaptionType of
                '1':  // Code Caption - Global Dimension using No. as Reference
                    case DimCaptionRef of
                        '1':
                            exit(
                              CodeCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Global Dimension 1 Code",
                                GLSetup.FieldCaption("Global Dimension 1 Code")));
                        '2':
                            exit(
                              CodeCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Global Dimension 2 Code",
                                GLSetup.FieldCaption("Global Dimension 2 Code")));
                    end;
                '2':  // Code Caption - Shortcut Dimension using No. as Reference
                    case DimCaptionRef of
                        '1':
                            exit(
                              CodeCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 1 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 1 Code")));
                        '2':
                            exit(
                              CodeCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 2 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 2 Code")));
                        '3':
                            exit(
                              CodeCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 3 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 3 Code")));
                        '4':
                            exit(
                              CodeCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 4 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 4 Code")));
                        '5':
                            exit(
                              CodeCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 5 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 5 Code")));
                        '6':
                            exit(
                              CodeCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 6 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 6 Code")));
                        '7':
                            exit(
                              CodeCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 7 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 7 Code")));
                        '8':
                            exit(
                              CodeCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 8 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 8 Code")));
                    end;
                '3':  // Filter Caption - Global Dimension using No. as Reference
                    case DimCaptionRef of
                        '1':
                            exit(
                              FilterCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Global Dimension 1 Code",
                                GLSetup.FieldCaption("Global Dimension 1 Code")));
                        '2':
                            exit(
                              FilterCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Global Dimension 2 Code",
                                GLSetup.FieldCaption("Global Dimension 2 Code")));
                    end;
                '4':  // Filter Caption - Shortcut Dimension using No. as Reference
                    case DimCaptionRef of
                        '1':
                            exit(
                              FilterCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 1 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 1 Code")));
                        '2':
                            exit(
                              FilterCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 2 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 2 Code")));
                        '3':
                            exit(
                              FilterCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 3 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 3 Code")));
                        '4':
                            exit(
                              FilterCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 4 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 4 Code")));
                        '5':
                            exit(
                              FilterCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 5 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 5 Code")));
                        '6':
                            exit(
                              FilterCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 6 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 6 Code")));
                        '7':
                            exit(
                              FilterCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 7 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 7 Code")));
                        '8':
                            exit(
                              FilterCaption(
                                Language, DimOptionalParam1, DimOptionalParam2,
                                GLSetup."Shortcut Dimension 8 Code",
                                GLSetup.FieldCaption("Shortcut Dimension 8 Code")));
                    end;
                '5':  // Code Caption - using Dimension Code as Reference
                    begin
                        if Dim.Get(DimCaptionRef) then
                            exit(DimOptionalParam1 + Dim.GetMLCodeCaption(Language) + DimOptionalParam2);
                        exit(DimOptionalParam1);
                    end;
                '6':  // Filter Caption - using Dimension Code as Reference
                    begin
                        if Dim.Get(DimCaptionRef) then
                            exit(DimOptionalParam1 + Dim.GetMLFilterCaption(Language) + DimOptionalParam2);
                        exit(DimOptionalParam1);
                    end;
                '7':   // Name Caption - Shortcut Dimension using No. as Reference
                    exit(ShortcutDimNameTranslate(Language, DimCaptionRef, DimOptionalParam1, DimOptionalParam2));

                else begin
                    IsHandled := false;
                    OnTranslateDimCaptionClassOnDimCaptionTypeCaseElse(DimCaptionType, DimCaptionRef, Language, DimOptionalParam1, DimOptionalParam2, Result, IsHandled);
                    if IsHandled then
                        exit(Result);
                end;
            end;
        end;
        Resolved := false;
        exit('');
    end;

    local procedure ShortcutDimNameTranslate(Language: Integer; DimCaptionRef: Text[80]; DimOptionalParam1: Text[80]; DimOptionalParam2: Text[80]) Result: Text
    begin
        if not GetGLSetup() then
            exit;
        case DimCaptionRef of
            '1':
                Result :=
                  DimNameCaption(
                    Language, DimOptionalParam1, DimOptionalParam2,
                    GLSetup."Shortcut Dimension 1 Code",
                    GLSetup.FieldCaption("Shortcut Dimension 1 Code"));
            '2':
                Result :=
                  DimNameCaption(
                    Language, DimOptionalParam1, DimOptionalParam2,
                    GLSetup."Shortcut Dimension 2 Code",
                    GLSetup.FieldCaption("Shortcut Dimension 2 Code"));
            '3':
                Result :=
                  DimNameCaption(
                    Language, DimOptionalParam1, DimOptionalParam2,
                    GLSetup."Shortcut Dimension 3 Code",
                    GLSetup.FieldCaption("Shortcut Dimension 3 Code"));
            '4':
                Result :=
                  DimNameCaption(
                    Language, DimOptionalParam1, DimOptionalParam2,
                    GLSetup."Shortcut Dimension 4 Code",
                    GLSetup.FieldCaption("Shortcut Dimension 4 Code"));
            '5':
                Result :=
                  DimNameCaption(
                    Language, DimOptionalParam1, DimOptionalParam2,
                    GLSetup."Shortcut Dimension 5 Code",
                    GLSetup.FieldCaption("Shortcut Dimension 5 Code"));
            '6':
                Result :=
                  DimNameCaption(
                    Language, DimOptionalParam1, DimOptionalParam2,
                    GLSetup."Shortcut Dimension 6 Code",
                    GLSetup.FieldCaption("Shortcut Dimension 6 Code"));
            '7':
                Result :=
                  DimNameCaption(
                    Language, DimOptionalParam1, DimOptionalParam2,
                    GLSetup."Shortcut Dimension 7 Code",
                    GLSetup.FieldCaption("Shortcut Dimension 7 Code"));
            '8':
                Result :=
                  DimNameCaption(
                    Language, DimOptionalParam1, DimOptionalParam2,
                    GLSetup."Shortcut Dimension 8 Code",
                    GLSetup.FieldCaption("Shortcut Dimension 8 Code"));
        end;
    end;

    local procedure CodeCaption(Language: Integer; DimOptionalParam1: Text; DimOptionalParam2: Text; DimCode: Code[20]; DimFieldCaption: Text[1024]): Text
    var
        Dim: Record Dimension;
    begin
        if Dim.Get(DimCode) then
            exit(DimOptionalParam1 + Dim.GetMLCodeCaption(Language) + DimOptionalParam2);
        exit(
          DimOptionalParam1 +
          DimFieldCaption +
          DimOptionalParam2);
    end;

    local procedure DimNameCaption(Language: Integer; DimOptionalParam1: Text; DimOptionalParam2: Text; DimCode: Code[20]; DimFieldCaption: Text): Text
    var
        Dim: Record Dimension;
    begin
        if Dim.Get(DimCode) then
            exit(DimOptionalParam1 + Dim.GetMLName(Language) + DimOptionalParam2);
        exit(DimOptionalParam1 + DimFieldCaption + DimOptionalParam2);
    end;

    local procedure FilterCaption(Language: Integer; DimOptionalParam1: Text; DimOptionalParam2: Text; DimCode: Code[20]; DimFieldCaption: Text[1024]): Text
    var
        Dim: Record Dimension;
    begin
        if Dim.Get(DimCode) then
            exit(DimOptionalParam1 + Dim.GetMLFilterCaption(Language) + DimOptionalParam2);
        exit(
          DimOptionalParam1 +
          DimFieldCaption +
          DimOptionalParam2);
    end;

    local procedure GetGLSetup(): Boolean
    begin
        if not GLSetupRead then
            GLSetupRead := GLSetup.Get();
        exit(GLSetupRead);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTranslateDimCaptionClassOnDimCaptionTypeCaseElse(DimCaptionType: Text[80]; DimCaptionRef: Text[80]; Language: Integer; DimOptionalParam1: Text[80]; DimOptionalParam2: Text[80]; var Result: Text; var IsHandled: Boolean)
    begin
    end;
}

