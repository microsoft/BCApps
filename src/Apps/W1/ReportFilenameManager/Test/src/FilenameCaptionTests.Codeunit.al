// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting.FileNaming;
using System.Globalization;
using System.TestLibraries.Utilities;

codeunit 149549 "Filename Caption Tests"
{
    // Test-owned resources exercise metadata selection, not the renderer's language or fallback contract.
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RequestedLanguageDoesNotDependOnCallerLanguage()
    var
        Caption: Text;
    begin
        Assert.IsTrue(ResolveCaption(Report::"Filename Caption Control", 1033, 1031, Caption), NotResolvedErr);
        Assert.AreEqual(GermanCaptionTok, Caption, WrongCaptionErr);

        Assert.IsTrue(ResolveCaption(Report::"Filename Caption Control", 1031, 1033, Caption), NotResolvedErr);
        Assert.AreEqual(EnglishCaptionTok, Caption, WrongCaptionErr);
    end;

    [Test]
    procedure BlankLanguageCodeUsesCallerLanguage()
    var
        Caption: Text;
    begin
        Assert.IsTrue(ResolveCaption(Report::"Filename Caption Control", 1033, 0, Caption), NotResolvedErr);
        Assert.AreEqual(EnglishCaptionTok, Caption, WrongCaptionErr);

        Assert.IsTrue(ResolveCaption(Report::"Filename Caption Control", 1031, 0, Caption), NotResolvedErr);
        Assert.AreEqual(GermanCaptionTok, Caption, WrongCaptionErr);
    end;

    [Test]
    procedure MissingTranslationReturnsSourceCaption()
    var
        Caption: Text;
    begin
        Assert.IsTrue(ResolveCaption(Report::"Filename Caption Missing", 1033, 1031, Caption), NotResolvedErr);
        Assert.AreEqual(UntranslatedCaptionTok, Caption, WrongCaptionErr);
    end;

    [Test]
    procedure ValidReportReplacesPreviousCaption()
    var
        Caption: Text;
    begin
        Caption := PreviousCaptionTok;

        Assert.IsTrue(ResolveCaption(Report::"Filename Caption Control", 1033, 1031, Caption), NotResolvedErr);
        Assert.AreEqual(GermanCaptionTok, Caption, WrongCaptionErr);
    end;

    [Test]
    procedure UnknownReportClearsPreviousCaption()
    var
        Caption: Text;
    begin
        Caption := PreviousCaptionTok;

        Assert.IsFalse(ResolveCaption(-1, 1033, 1031, Caption), InvalidReportResolvedErr);
        Assert.AreEqual('', Caption, StaleCaptionErr);
    end;

    [Test]
    procedure EmptyReportIdClearsPreviousCaption()
    var
        Caption: Text;
    begin
        Caption := PreviousCaptionTok;

        Assert.IsFalse(ResolveCaption(0, 1031, 1033, Caption), InvalidReportResolvedErr);
        Assert.AreEqual('', Caption, StaleCaptionErr);
    end;

    [Test]
    procedure UnknownReportWithEmptyOutputDoesNotResolve()
    var
        Caption: Text;
    begin
        Assert.IsFalse(ResolveCaption(-1, 1031, 1033, Caption), InvalidReportResolvedErr);
        Assert.AreEqual('', Caption, StaleCaptionErr);
    end;

    local procedure ResolveCaption(ReportId: Integer; CallerLanguageId: Integer; RequestedLanguageId: Integer; var Caption: Text) Resolved: Boolean
    var
        LanguageMgt: Codeunit Language;
        PreviousLanguageId: Integer;
        LanguageAfterResolve: Integer;
        ReadSucceeded: Boolean;
        FailureText: Text;
    begin
        PreviousLanguageId := GlobalLanguage();
        GlobalLanguage(CallerLanguageId);
        // The one-shot override avoids relying on company language rows or installed Base App translations.
        LanguageMgt.SetOverrideLanguageId(RequestedLanguageId);
        ReadSucceeded := TryResolveCaption(ReportId, Caption, Resolved);
        if not ReadSucceeded then
            FailureText := GetLastErrorText();
        LanguageAfterResolve := GlobalLanguage();
        LanguageMgt.SetOverrideLanguageId(0);
        GlobalLanguage(PreviousLanguageId);

        Assert.IsTrue(ReadSucceeded, FailureText);
        Assert.AreEqual(CallerLanguageId, LanguageAfterResolve, LanguageNotRestoredErr);
    end;

    [TryFunction]
    local procedure TryResolveCaption(ReportId: Integer; var Caption: Text; var Resolved: Boolean)
    var
        Pattern: Record "Report Filename Pattern";
        Document: RecordRef;
        Placeholder: Interface "Report Filename Placeholder";
    begin
        Placeholder := Enum::"Report Filename Placeholder"::ReportName;
        Resolved := Placeholder.TryResolve(Pattern, ReportId, Document, '', Caption);
    end;

    var
        Assert: Codeunit "Library Assert";
        EnglishCaptionTok: Label 'Caption probe EN', Locked = true;
        GermanCaptionTok: Label 'Caption probe DE', Locked = true;
        UntranslatedCaptionTok: Label 'Caption probe untranslated', Locked = true;
        PreviousCaptionTok: Label 'Previous report caption', Locked = true;
        NotResolvedErr: Label 'The report caption was not resolved.';
        WrongCaptionErr: Label 'The caption did not match the requested language resource.';
        InvalidReportResolvedErr: Label 'A nonexistent report must not resolve a caption.';
        StaleCaptionErr: Label 'A nonexistent report must clear the previous caption.';
        LanguageNotRestoredErr: Label 'Resolving a caption did not restore the caller language.';
}
