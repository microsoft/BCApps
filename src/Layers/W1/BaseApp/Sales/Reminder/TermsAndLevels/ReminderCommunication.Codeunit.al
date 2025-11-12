// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Sales.Receivables;
using Microsoft.Foundation.Company;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Sales.Customer;
using System.Globalization;
using System.Text;
using Microsoft.Sales.FinanceCharge;
#if not CLEAN26
using System.Environment.Configuration;
#endif
using System.Reflection;
using Microsoft.Foundation.Reporting;
using System.EMail;
using System.Utilities;

codeunit 1890 "Reminder Communication"
{

    internal procedure NewReminderCommunicationEnabled(): Boolean
#if not CLEAN26
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#endif
    begin
#if not CLEAN26
        exit(FeatureManagementFacade.IsEnabled(FeatureIdTok));
#else
    exit(true);
#endif
    end;

    procedure FindDescriptionForLineFee(var ReminderLevel: Record "Reminder Level"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var ReminderLine: Record "Reminder Line"; var GLAccount: Record "G/L Account"): Text[100]
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        LanguageCode: Code[10];
        Result: Text[100];
    begin
        if NewReminderCommunicationEnabled() then begin
            LanguageCode := GetCustomerLanguageOrDefaultUserLanguage(CustLedgerEntry."Customer No.");

            // Check if there is a reminder attachment text for the Reminder Level
            if ReminderAttachmentText.Get(ReminderLevel."Reminder Attachment Text", LanguageCode) then
                Result := SubstituteInlineFeeDescription(ReminderAttachmentText."Inline Fee Description", ReminderLevel, ReminderLine)
            else begin
                // If there are no reminder attachment text for the language, check the Reminder Terms attachment text
                ReminderTerms.Get(ReminderLevel."Reminder Terms Code");
                if ReminderAttachmentText.Get(ReminderTerms."Reminder Attachment Text", LanguageCode) then
                    Result := SubstituteInlineFeeDescription(ReminderAttachmentText."Inline Fee Description", ReminderLevel, ReminderLine)
            end;
        end
        else
            Result := SubstituteInlineFeeDescription(ReminderLevel."Add. Fee per Line Description", ReminderLevel, ReminderLine);

        if Result = '' then
            if GLAccount.Get(ReminderLine."No.") then
                Result := GLAccount.Name;
        exit(Result);
    end;

    procedure InsertBeginningText(var ReminderHeader: Record "Reminder Header"; var ReminderLevel: Record "Reminder Level"; var ReminderLine: Record "Reminder Line")
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        LineSpacing, NextLineNo : Integer;
        LanguageCode: Code[10];
    begin
        if NewReminderCommunicationEnabled() then begin
            LanguageCode := GetCustomerLanguageOrDefaultUserLanguage(ReminderHeader."Customer No.");
            ReminderLine.Reset();
            ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
            ReminderLine."Reminder No." := ReminderHeader."No.";

            if ReminderAttachmentText.Get(ReminderLevel."Reminder Attachment Text", LanguageCode) then begin
                LineSpacing := CalculateLineSpacingForBeginningText(ReminderLine, ReminderAttachmentText);
                ReminderHeader.InsertTextLines(ReminderHeader, ReminderAttachmentText, Enum::"Reminder Line Type"::"Beginning Text", NextLineNo, LineSpacing);
            end
            else begin
                ReminderTerms.Get(ReminderLevel."Reminder Terms Code");
                if ReminderAttachmentText.Get(ReminderTerms."Reminder Attachment Text", LanguageCode) then begin
                    LineSpacing := CalculateLineSpacingForBeginningText(ReminderLine, ReminderAttachmentText);
                    ReminderHeader.InsertTextLines(ReminderHeader, ReminderAttachmentText, Enum::"Reminder Line Type"::"Beginning Text", NextLineNo, LineSpacing)
                end;
            end;
        end;

#if not CLEAN26
        if not NewReminderCommunicationEnabled() then
            IntroduceBeginningTextFromReminderText(ReminderHeader, ReminderLevel, ReminderLine);
#endif
    end;

    procedure InsertEndingText(var ReminderHeader: Record "Reminder Header"; var ReminderLevel: Record "Reminder Level"; var ReminderLine: Record "Reminder Line")
    var
        ReminderLine2: Record "Reminder Line";
        ReminderTerms: Record "Reminder Terms";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        LanguageCode: Code[10];
        LineSpacing, NextLineNo : Integer;
    begin
        if NewReminderCommunicationEnabled() then begin
            LanguageCode := GetCustomerLanguageOrDefaultUserLanguage(ReminderHeader."Customer No.");
            ReminderLine.Reset();
            ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
            ReminderLine.SetFilter(
              "Line Type", '%1|%2|%3',
              ReminderLine."Line Type"::"Reminder Line",
              ReminderLine."Line Type"::"Additional Fee",
              ReminderLine."Line Type"::Rounding);

            if ReminderLine.FindLast() then
                NextLineNo := ReminderLine."Line No."
            else
                NextLineNo := 0;

            ReminderLine.SetRange("Line Type");
            ReminderLine2 := ReminderLine;
            ReminderLine2.CopyFilters(ReminderLine);
            ReminderLine2.SetFilter("Line Type", '<>%1', ReminderLine2."Line Type"::"Line Fee");

            if ReminderAttachmentText.Get(ReminderLevel."Reminder Attachment Text", LanguageCode) then begin
                LineSpacing := CalculateLineSpacingForEndingText(ReminderLine, ReminderLine2, ReminderAttachmentText);
                ReminderHeader.InsertTextLines(ReminderHeader, ReminderAttachmentText, Enum::"Reminder Line Type"::"Ending Text", NextLineNo, LineSpacing);
            end
            else begin
                ReminderTerms.Get(ReminderLevel."Reminder Terms Code");
                if ReminderAttachmentText.Get(ReminderTerms."Reminder Attachment Text", LanguageCode) then begin
                    LineSpacing := CalculateLineSpacingForEndingText(ReminderLine, ReminderLine2, ReminderAttachmentText);
                    ReminderHeader.InsertTextLines(ReminderHeader, ReminderAttachmentText, Enum::"Reminder Line Type"::"Ending Text", NextLineNo, LineSpacing);
                end;
            end;
        end;

#if not CLEAN26
        if not NewReminderCommunicationEnabled() then
            IntroduceEndingTextFromReminderText(ReminderHeader, ReminderLevel, ReminderLine);
#endif
    end;

#if not CLEAN26
    [Obsolete('Reminder Text is being obsoleted. Use the new records Reminder Attachment Text and Reminder Email Text', '24.0')]
    local procedure IntroduceBeginningTextFromReminderText(var ReminderHeader: Record "Reminder Header"; var ReminderLevel: Record "Reminder Level"; var ReminderLine: Record "Reminder Line")
    var
        ReminderText: Record "Reminder Text";
        LineSpacing, NextLineNo : Integer;
    begin
        ReminderText.Reset();
        ReminderText.SetRange("Reminder Terms Code", ReminderHeader."Reminder Terms Code");
        ReminderText.SetRange("Reminder Level", ReminderLevel."No.");
        ReminderText.SetRange(Position, ReminderText.Position::Beginning);
        ReminderHeader.OnInsertBeginTextsOnAfterReminderTextSetFilters(ReminderText, ReminderHeader);

        ReminderLine.Reset();
        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        ReminderLine."Reminder No." := ReminderHeader."No.";
        if ReminderLine.Find('-') then begin
            LineSpacing := ReminderLine."Line No." div (ReminderText.Count + 2);
            if LineSpacing = 0 then
                Error(NoEnoughSpaceForTextErr);
        end else
            LineSpacing := 10000;

        NextLineNo := 0;
        ReminderHeader.InsertTextLines(ReminderHeader, ReminderText, NextLineNo, LineSpacing);
    end;

    [Obsolete('Reminder Text is being obsoleted. Use the new records Reminder Attachment Text and Reminder Email Text', '24.0')]
    local procedure IntroduceEndingTextFromReminderText(var ReminderHeader: Record "Reminder Header"; var ReminderLevel: Record "Reminder Level"; var ReminderLine: Record "Reminder Line")
    var
        ReminderText: Record "Reminder Text";
        ReminderLine2: Record "Reminder Line";
        LineSpacing, NextLineNo : Integer;
    begin
        ReminderText.SetRange("Reminder Terms Code", ReminderHeader."Reminder Terms Code");
        ReminderText.SetRange("Reminder Level", ReminderLevel."No.");
        ReminderText.SetRange(Position, ReminderText.Position::Ending);
        ReminderHeader.OnInsertEndTextsOnAfterReminderTextSetFilters(ReminderText, ReminderHeader);

        ReminderLine.Reset();
        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        ReminderLine.SetFilter(
            "Line Type", '%1|%2|%3',
            ReminderLine."Line Type"::"Reminder Line",
            ReminderLine."Line Type"::"Additional Fee",
            ReminderLine."Line Type"::Rounding);
        ReminderHeader.OnInsertEndTextsOnAfterReminderLineSetFilters(ReminderLine, ReminderHeader);
        if ReminderLine.FindLast() then
            NextLineNo := ReminderLine."Line No."
        else
            NextLineNo := 0;
        ReminderLine.SetRange("Line Type");
        ReminderLine2 := ReminderLine;
        ReminderLine2.CopyFilters(ReminderLine);
        ReminderLine2.SetFilter("Line Type", '<>%1', ReminderLine2."Line Type"::"Line Fee");
        if ReminderLine2.Next() <> 0 then begin
            LineSpacing :=
              (ReminderLine2."Line No." - ReminderLine."Line No.") div
              (ReminderText.Count + 2);
            if LineSpacing = 0 then
                Error(NoEnoughSpaceForTextErr);
        end else
            LineSpacing := 10000;
        ReminderHeader.InsertTextLines(ReminderHeader, ReminderText, NextLineNo, LineSpacing);
    end;
#endif

    local procedure GetCustomerLanguageOrDefaultUserLanguage(CustomerNo: Code[20]): Code[10]
    var
        Customer: Record Customer;
        Language: Codeunit Language;
        LanguageCode: Code[10];
    begin
        if Customer.Get(CustomerNo) then
            LanguageCode := Customer."Language Code";

        if LanguageCode = '' then
            LanguageCode := Language.GetUserLanguageCode();

        if LanguageCode = '' then
            LanguageCode := Language.GetLanguageCode(Language.GetDefaultApplicationLanguageId());

        exit(LanguageCode);
    end;

    procedure SubstituteInlineFeeDescription(FeeLineDescriptionText: Text[100]; var ReminderLevel: Record "Reminder Level"; var ReminderLine: Record "Reminder Line"): Text[100]
    begin
        // Here we should work on improving the user experience instead of inputting %1, %2, %3.
        exit(StrSubstNo(FeeLineDescriptionText,
                ReminderLine."Reminder No.",
                ReminderLine."No. of Reminders",
                ReminderLine."Document Date",
                ReminderLine."Posting Date",
                ReminderLine."No.",
                ReminderLine.Amount,
                ReminderLine."Applies-to Document Type",
                ReminderLine."Applies-to Document No.",
                ReminderLevel."No."))
    end;

    procedure SubstituteBeginningOrEndingDescription(SourceDescriptionText: Text[100]; ReminderTotal: Decimal; MaxLength: Integer; var ReminderHeader: Record "Reminder Header"; var FinanceChargeTerms: Record "Finance Charge Terms"): Text[100]
    var
        CompanyInfo: Record "Company Information";
        AutoFormat: Codeunit "Auto Format";
        AutoFormatType: Enum "Auto Format";
    begin
        CompanyInfo.Get();
        if MaxLength > 100 then
            MaxLength := 100;
        // Here we should work on improving the user experience instead of inputting %1, %2, %3.
        exit(CopyStr(CopyStr(
            StrSubstNo(
                SourceDescriptionText,
                ReminderHeader."Document Date",
                ReminderHeader."Due Date",
                FinanceChargeTerms."Interest Rate",
                Format(
                    ReminderHeader."Remaining Amount",
                    0,
                    AutoFormat.ResolveAutoFormat(
                        AutoFormatType::AmountFormat,
                        ReminderHeader."Currency Code")),
                ReminderHeader."Interest Amount",
                ReminderHeader."Additional Fee",
                Format(
                    ReminderTotal,
                    0,
                    AutoFormat.ResolveAutoFormat(
                        AutoFormatType::AmountFormat,
                        ReminderHeader."Currency Code")),
                ReminderHeader."Reminder Level",
                ReminderHeader."Currency Code",
                ReminderHeader."Posting Date",
                CompanyInfo.Name,
                ReminderHeader."Add. Fee per Line"),
            1, MaxLength),
            1, 100));
    end;

    procedure GetListOfAttachmentLanguagesFromIdWithSeparator(SelectedGuid: Guid; SeparatorText: Text): Text
    var
        LanguageCodes: List of [Code[10]];
    begin
        LanguageCodes := GetListOfAttachmentLanguagesFromId(SelectedGuid);
        exit(GenerateTextofLanguagesFromListOfCode(LanguageCodes, SeparatorText));
    end;

    procedure GetListOfEmailLanguagesFromIdWithSeparator(SelectedGuid: Guid; SeparatorText: Text): Text
    var
        LanguageCodes: List of [Code[10]];
    begin
        LanguageCodes := GetListOfEmailLanguagesFromId(SelectedGuid);
        exit(GenerateTextofLanguagesFromListOfCode(LanguageCodes, SeparatorText));
    end;

    local procedure GenerateTextofLanguagesFromListOfCode(var LanguageCodes: List of [Code[10]]; SeparatorText: Text): Text
    var
        LanguageCode: Text;
        ResultingText: Text;
        FirstLanguage: Boolean;
    begin
        FirstLanguage := true;
        foreach LanguageCode in LanguageCodes do
            if FirstLanguage then begin
                ResultingText := LanguageCode;
                FirstLanguage := false;
            end
            else
                ResultingText := StrSubstNo(SeparatorText, ResultingText, LanguageCode);
        exit(ResultingText);
    end;

    procedure GetListOfAttachmentLanguagesFromId(SelectedGuid: Guid): List of [Code[10]]
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        LanguageCodes: List of [Code[10]];
    begin
        if IsNullGuid(SelectedGuid) then
            exit(LanguageCodes);

        ReminderAttachmentText.SetRange(Id, SelectedGuid);
        if ReminderAttachmentText.IsEmpty() then
            exit(LanguageCodes);

        if ReminderAttachmentText.FindSet() then
            repeat
                LanguageCodes.Add(ReminderAttachmentText."Language Code");
            until ReminderAttachmentText.Next() = 0;
        exit(LanguageCodes);
    end;

    procedure GetListOfEmailLanguagesFromId(SelectedGuid: Guid): List of [Code[10]]
    var
        ReminderEmailText: Record "Reminder Email Text";
        LanguageCodes: List of [Code[10]];
    begin
        if IsNullGuid(SelectedGuid) then
            exit(LanguageCodes);

        ReminderEmailText.SetRange(Id, SelectedGuid);
        if ReminderEmailText.IsEmpty() then
            exit(LanguageCodes);

        if ReminderEmailText.FindSet() then
            repeat
                LanguageCodes.Add(ReminderEmailText."Language Code");
            until ReminderEmailText.Next() = 0;
        exit(LanguageCodes);
    end;

    procedure SetDefaultContentForNewLanguage(SelectedId: Guid; LanguageCode: Code[10]; SourceType: Enum "Reminder Text Source Type"; SelectedSystemId: Guid)
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderEmailText: Record "Reminder Email Text";
    begin
        ReminderAttachmentText.SetDefaultContentForNewLanguage(SelectedId, LanguageCode, SourceType, SelectedSystemId);
        ReminderEmailText.SetDefaultContentForNewLanguage(SelectedId, LanguageCode, SourceType, SelectedSystemId);
    end;

    procedure ExtractAttachmentAndEmailLanguages(var ReminderTerms: Record "Reminder Terms"): Text
    begin
        exit(ExtractAttachmentAndEmailLanguages(ReminderTerms."Reminder Attachment Text"));
    end;

    procedure ExtractAttachmentAndEmailLanguages(var ReminderLevel: Record "Reminder Level"): Text
    begin
        exit(ExtractAttachmentAndEmailLanguages(ReminderLevel."Reminder Attachment Text"));
    end;

    procedure ExtractAttachmentAndEmailLanguages(SelectedId: Guid): Text
    var
        AttachmentLanguages: Text;
        EmailLanguages: Text;
    begin
        AttachmentLanguages := GetListOfAttachmentLanguagesFromIdWithSeparator(SelectedId, CommaSeparatedTok);
        EmailLanguages := GetListOfEmailLanguagesFromIdWithSeparator(SelectedId, CommaSeparatedTok);
        exit(StrSubstNo(LanguagesCustomerCommunicationsLbl, AttachmentLanguages, EmailLanguages));
    end;

    procedure PopulateEmailText(var IssuedReminderHeader: Record "Issued Reminder Header"; var CompanyInfo: Record "Company Information"; var GreetingTxt: Text; var AmtDueTxt: Text; var BodyTxt: Text; var ClosingTxt: Text; var DescriptionTxt: Text; NNC_TotalInclVAT: Decimal)
    var
        ReminderEmailText: Record "Reminder Email Text";
        MailManagement: Codeunit "Mail Management";
    begin
        if NewReminderCommunicationEnabled() then begin
            AmtDueTxt := '';
            GreetingTxt := '';
            ClosingTxt := '';
            BodyTxt := ReplaceTextTok;
            DescriptionTxt := ReminderEmailText.GetDescriptionLbl();
            IssuedReminderHeader.CalcFields("Email Text");

            ReminderEmailText.SetAutoCalcFields("Body Text");
            if GetReminderEmailText(IssuedReminderHeader, ReminderEmailText) then begin
                GreetingTxt := ReminderEmailText.Greeting;
                ClosingTxt := ReminderEmailText.Closing;
                if Format(IssuedReminderHeader."Due Date") <> '' then
                    if not MailManagement.IsHandlingGetEmailBody() then begin
                        SelectEmailBodyText(ReminderEmailText, IssuedReminderHeader, AmtDueTxt);
                        AmtDueTxt := StripHtmlTags(AmtDueTxt);
                        SubstituteRelatedValues(AmtDueTxt, IssuedReminderHeader, IssuedReminderHeader.CalculateTotalIncludingVAT(), CopyStr(CompanyName, 1, 100));
                    end;
            end else begin
                GreetingTxt := ReminderEmailText.GetDefaultGreetingLbl();
                if Format(IssuedReminderHeader."Due Date") <> '' then
                    AmtDueTxt := StrSubstNo(ReminderEmailText.GetAmtDueLbl(), IssuedReminderHeader."Due Date");
                ClosingTxt := ReminderEmailText.GetDefaultClosingLbl();
            end;
            SubstituteRelatedValues(GreetingTxt, IssuedReminderHeader, IssuedReminderHeader.CalculateTotalIncludingVAT(), CopyStr(CompanyName, 1, 100));
            SubstituteRelatedValues(ClosingTxt, IssuedReminderHeader, IssuedReminderHeader.CalculateTotalIncludingVAT(), CopyStr(CompanyName, 1, 100));
        end;
#if not CLEAN26
        if not NewReminderCommunicationEnabled() then
            PopulateEmailTextFromReminderText(IssuedReminderHeader, CompanyInfo, GreetingTxt, AmtDueTxt, BodyTxt, ClosingTxt, DescriptionTxt, NNC_TotalInclVAT);
#endif
    end;

    local procedure SelectEmailBodyText(var ReminderEmailText: Record "Reminder Email Text"; var IssuedReminderHeader: Record "Issued Reminder Header"; var BodyTxt: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        EmailBodyTextInStream: InStream;
    begin
        // if there is an email text on the reminder itself, read that it  
        if IssuedReminderHeader."Email Text".HasValue() then begin
            IssuedReminderHeader."Email Text".CreateInStream(EmailBodyTextInStream, TextEncoding::UTF8);
            BodyTxt := TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(EmailBodyTextInStream, TypeHelper.LFSeparator(), IssuedReminderHeader.FieldName("Email Text"));
        end
        else
            BodyTxt += ReminderEmailText.GetBodyText();
    end;

    local procedure SelectEmailBodyText(var IssuedReminderHeader: Record "Issued Reminder Header"; var BodyTxt: Text)
    var
        ReminderEmailText: Record "Reminder Email Text";
        TypeHelper: Codeunit "Type Helper";
        EmailBodyTextInStream: InStream;
    begin
        // if there is an email text on the reminder itself, read that it  
        if IssuedReminderHeader."Email Text".HasValue() then begin
            IssuedReminderHeader."Email Text".CreateInStream(EmailBodyTextInStream, TextEncoding::UTF8);
            BodyTxt := TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(EmailBodyTextInStream, TypeHelper.LFSeparator(), IssuedReminderHeader.FieldName("Email Text"));
        end
        else
            BodyTxt := ReminderEmailText.GetBodyLbl();
    end;

    local procedure SubstituteRelatedValues(var BodyTxt: Text; var IssuedReminderHeader: Record "Issued Reminder Header"; NNC_TotalInclVAT: Decimal; CompanyName: Text[100])
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        AutoFormat: Codeunit "Auto Format";
        AutoFormatType: Enum "Auto Format";
    begin
        if IssuedReminderHeader."Fin. Charge Terms Code" <> '' then
            FinanceChargeTerms.Get(IssuedReminderHeader."Fin. Charge Terms Code");

        BodyTxt := StrSubstNo(
            BodyTxt,
            IssuedReminderHeader."Document Date",
            IssuedReminderHeader."Due Date",
            FinanceChargeTerms."Interest Rate",
            Format(IssuedReminderHeader."Remaining Amount", 0,
                AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, IssuedReminderHeader."Currency Code")),
            IssuedReminderHeader."Interest Amount",
            IssuedReminderHeader."Additional Fee",
            Format(NNC_TotalInclVAT, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, IssuedReminderHeader."Currency Code")),
            IssuedReminderHeader."Reminder Level",
            IssuedReminderHeader."Currency Code",
            IssuedReminderHeader."Posting Date",
            CompanyName,
            IssuedReminderHeader."Add. Fee per Line");

        OnAfterSubstituteRelatedValues(BodyTxt, IssuedReminderHeader);
    end;

#if not CLEAN26
    local procedure PopulateEmailTextFromReminderText(var IssuedReminderHeader: Record "Issued Reminder Header"; var CompanyInfo: Record "Company Information"; var GreetingTxt: Text; var AmtDueTxt: Text; var BodyTxt: Text; var ClosingTxt: Text; var DescriptionTxt: Text; NNC_TotalInclVAT: Decimal)
    var
        ReminderEmailText: Record "Reminder Email Text";
        EmailTextInStream: InStream;
        EmailTextLine: Text;
    begin
        AmtDueTxt := '';
        BodyTxt := '';
        GreetingTxt := ReminderEmailText.GetDefaultGreetingLbl();
        ClosingTxt := ReminderEmailText.GetDefaultClosingLbl();
        DescriptionTxt := ReminderEmailText.GetDescriptionLbl();
        if Format(IssuedReminderHeader."Due Date") <> '' then
            AmtDueTxt := StrSubstNo(ReminderEmailText.GetAmtDueLbl(), IssuedReminderHeader."Due Date");

        if GetEmailTextInStream(EmailTextInStream, IssuedReminderHeader) then begin
            AmtDueTxt := '';
            BodyTxt := '';

            while EmailTextInStream.ReadText(EmailTextLine) > 0 do
                BodyTxt += EmailTextLine;

            SubstituteRelatedValues(BodyTxt, IssuedReminderHeader, NNC_TotalInclVAT, CompanyInfo.Name);
        end else
            BodyTxt := ReminderEmailText.GetBodyLbl();
    end;

    local procedure GetEmailTextInStream(var EmailTextInStream: InStream; var IssuedReminderHeader: Record "Issued Reminder Header"): Boolean
    var
        ReminderText: Record "Reminder Text";
        ReminderTextPosition: Enum "Reminder Text Position";
    begin
        IssuedReminderHeader.CalcFields("Email Text");
        ReminderText.SetAutoCalcFields("Email Text");

        // if there is email text on the reminder, prepare to read it                       
        if IssuedReminderHeader."Email Text".HasValue() then begin
            IssuedReminderHeader."Email Text".CreateInStream(EmailTextInStream);
            exit(true);
        end;

        // otherwise, if there is email text on the reminder level, prepare to read it                       
        if ReminderText.Get(IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level", ReminderTextPosition::"Email Body", 0) then
            if ReminderText."Email Text".HasValue() then begin
                ReminderText."Email Text".CreateInStream(EmailTextInstream);
                exit(true);
            end;

        // otherwise, if there is email text on the reminder terms, prepare to read it                       
        if ReminderText.Get(IssuedReminderHeader."Reminder Terms Code", 0, ReminderTextPosition::"Email Body", 0) then
            if ReminderText."Email Text".HasValue() then begin
                ReminderText."Email Text".CreateInStream(EmailTextInstream);
                exit(true)
            end;

        exit(false)
    end;
#endif

    internal procedure CheckMissMatchBetweenLanguages(var ReminderTerms: Record "Reminder Terms"): Boolean
    var
        ReminderLevel: Record "Reminder Level";
        ReminderCommunication: Codeunit "Reminder Communication";
        ReminderTermsAttachmentLanguages: Text;
        ReminderTermsEmailLanguages: Text;
        ReminderLevelAttachmentLanguages: Text;
        ReminderLevelEmailLanguages: Text;
        PreviousReminderLevelAttachmentLanguages: Text;
        PreviousReminderLevelEmailLanguages: Text;
        AffectedReminderLevels: Text;
        FirstLevel: Boolean;
        MissalignedLevels: Boolean;
        ConfirmMessage: Text;
    begin
        ReminderTermsAttachmentLanguages := ReminderCommunication.GetListOfAttachmentLanguagesFromIdWithSeparator(ReminderTerms."Reminder Attachment Text", CommaSeparatedTok);
        ReminderTermsEmailLanguages := ReminderCommunication.GetListOfEmailLanguagesFromIdWithSeparator(ReminderTerms."Reminder Email Text", CommaSeparatedTok);
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTerms.Code);
        if not ReminderLevel.IsEmpty() then begin
            FirstLevel := true;
            ReminderLevel.FindSet();
            repeat
                ReminderLevelAttachmentLanguages := ReminderCommunication.GetListOfAttachmentLanguagesFromIdWithSeparator(ReminderLevel."Reminder Attachment Text", CommaSeparatedTok);
                ReminderLevelEmailLanguages := ReminderCommunication.GetListOfEmailLanguagesFromIdWithSeparator(ReminderLevel."Reminder Email Text", CommaSeparatedTok);
                if (ReminderTermsAttachmentLanguages <> ReminderLevelAttachmentLanguages) or (ReminderTermsEmailLanguages <> ReminderLevelEmailLanguages) then
                    if AffectedReminderLevels = '' then
                        AffectedReminderLevels := Format(ReminderLevel."No.")
                    else
                        AffectedReminderLevels := StrSubstNo(CommaSeparatedTok, AffectedReminderLevels, ReminderLevel."No.");

                if FirstLevel then
                    FirstLevel := false
                else
                    if (PreviousReminderLevelAttachmentLanguages <> ReminderLevelAttachmentLanguages) or (PreviousReminderLevelEmailLanguages <> ReminderLevelEmailLanguages) then
                        MissalignedLevels := true;

                PreviousReminderLevelAttachmentLanguages := ReminderLevelAttachmentLanguages;
                PreviousReminderLevelEmailLanguages := ReminderLevelEmailLanguages;
            until ReminderLevel.Next() = 0;
        end;

        if AffectedReminderLevels <> '' then begin
            ConfirmMessage := StrSubstNo(MismatchLanguagesBetweenTermsAndLevelsMsg, AffectedReminderLevels);
            if MissalignedLevels then
                ConfirmMessage := StrSubstNo(AppendixTextTok, ConfirmMessage, ExtensionMismatchLanguagesBetweenTermsAndLevelsMsg);
        end
        else
            if MissalignedLevels then
                ConfirmMessage := MismatchLanguagesBetweenLevelsMsg;

        if ConfirmMessage <> '' then
            exit(Confirm(ConfirmMessage));

        exit(false);
    end;

    internal procedure TransferReminderText()
    var
        ReminderLevels: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
        ReminderEmailText: Record "Reminder Email Text";
        Language: Codeunit Language;
        TypeHelper: Codeunit "Type Helper";
        ReadStream: InStream;
        DefaultLanguageCode: Code[10];
        LocalGuid: Guid;
    begin
        if ReminderText.IsEmpty() then
            exit;
        DefaultLanguageCode := Language.GetUserLanguageCode();
        ReminderText.FindSet();
        repeat
            Clear(ReminderAttachmentText);
            Clear(ReminderEmailText);
            Clear(LocalGuid);
            Clear(ReadStream);
            // Check if there are existing texts for the reminder level
            if ReminderLevels.Get(ReminderText."Reminder Terms Code", ReminderText."Reminder Level") then begin

                if not IsNullGuid(ReminderLevels."Reminder Attachment Text") then
                    LocalGuid := ReminderLevels."Reminder Attachment Text";
                if not IsNullGuid(ReminderLevels."Reminder Email Text") then
                    LocalGuid := ReminderLevels."Reminder Email Text";
                if IsNullGuid(LocalGuid) then
                    LocalGuid := CreateGuid();
                // If not then create the default ones
                if not ReminderAttachmentText.Get(LocalGuid, DefaultLanguageCode) then
                    ReminderAttachmentText.SetDefaultContentForNewLanguage(LocalGuid, DefaultLanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", ReminderLevels.SystemId);

                if not ReminderEmailText.Get(LocalGuid, DefaultLanguageCode) then
                    ReminderEmailText.SetDefaultContentForNewLanguage(LocalGuid, DefaultLanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", ReminderLevels.SystemId);
                if ReminderAttachmentText.Get(LocalGuid, DefaultLanguageCode) and ReminderEmailText.Get(LocalGuid, DefaultLanguageCode) then
                    // And then personalized them with the customer data
                    case ReminderText.Position of
                        Enum::"Reminder Text Position"::Beginning:
                            begin
                                ReminderAttachmentTextLine.Init();
                                ReminderAttachmentTextLine.Id := ReminderAttachmentText.Id;
                                ReminderAttachmentTextLine."Language Code" := ReminderAttachmentText."Language Code";
                                ReminderAttachmentTextLine.Position := ReminderAttachmentTextLine.Position::"Beginning Line";
                                ReminderAttachmentTextLine."Line No." := ReminderText."Line No.";
                                ReminderAttachmentTextLine.Text := ReminderText.Text;
                                ReminderAttachmentTextLine.Insert(true);
                            end;
                        Enum::"Reminder Text Position"::Ending:
                            begin
                                ReminderAttachmentTextLine.Init();
                                ReminderAttachmentTextLine.Id := ReminderAttachmentText.Id;
                                ReminderAttachmentTextLine."Language Code" := ReminderAttachmentText."Language Code";
                                ReminderAttachmentTextLine.Position := ReminderAttachmentTextLine.Position::"Ending Line";
                                ReminderAttachmentTextLine."Line No." := ReminderText."Line No.";
                                ReminderAttachmentTextLine.Text := ReminderText.Text;
                                ReminderAttachmentTextLine.Insert(true);
                            end;
                        Enum::"Reminder Text Position"::"Email Body":
                            if ReminderText."Email Text".HasValue() then begin
                                ReminderText.CalcFields("Email Text");
                                ReminderText."Email Text".CreateInStream(ReadStream);
                                ReminderEmailText.SetBodyText(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(ReadStream, TypeHelper.LFSeparator(), ReminderText.FieldName("Email Text")));
                            end;
                    end;
            end;
        until ReminderText.Next() = 0;
    end;

    internal procedure TransferReminderTermsTranslations()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderTermsTranslations: Record "Reminder Terms Translation";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderEmailText: Record "Reminder Email Text";
        LocalGuid: Guid;
    begin
        if ReminderTermsTranslations.IsEmpty() then
            exit;
        ReminderTermsTranslations.FindSet();
        repeat
            Clear(ReminderAttachmentText);
            Clear(ReminderEmailText);
            Clear(LocalGuid);
            if ReminderTerms.Get(ReminderTermsTranslations."Reminder Terms Code") then begin
                if not IsNullGuid(ReminderTerms."Reminder Attachment Text") then
                    LocalGuid := ReminderTerms."Reminder Attachment Text";
                if not IsNullGuid(ReminderTerms."Reminder Email Text") then
                    LocalGuid := ReminderTerms."Reminder Email Text";
                if IsNullGuid(LocalGuid) then
                    LocalGuid := CreateGuid();
                if not ReminderAttachmentText.Get(LocalGuid, ReminderTermsTranslations."Language Code") then
                    ReminderAttachmentText.SetDefaultContentForNewLanguage(LocalGuid, ReminderTermsTranslations."Language Code", Enum::"Reminder Text Source Type"::"Reminder Term", ReminderTerms.SystemId);
                if not ReminderEmailText.Get(LocalGuid, ReminderTermsTranslations."Language Code") then
                    ReminderEmailText.SetDefaultContentForNewLanguage(LocalGuid, ReminderTermsTranslations."Language Code", Enum::"Reminder Text Source Type"::"Reminder Term", ReminderTerms.SystemId);
                if ReminderAttachmentText.Get(LocalGuid, ReminderTermsTranslations."Language Code") then begin
                    ReminderAttachmentText."Inline Fee Description" := CopyStr(ReminderTermsTranslations."Note About Line Fee on Report", 1, 100);
                    ReminderAttachmentText.Modify(true);
                end;
            end;
        until ReminderTermsTranslations.Next() = 0;
    end;

    internal procedure TransferReminderTermsLineFeeDescription()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderEmailText: Record "Reminder Email Text";
        Language: Codeunit Language;
        LocalGuid: Guid;
        DefaultLanguageCode: Code[10];
    begin
        if ReminderTerms.IsEmpty() then
            exit;
        DefaultLanguageCode := Language.GetLanguageCode(Language.GetDefaultApplicationLanguageId());
        ReminderTerms.FindSet();
        repeat
            Clear(ReminderAttachmentText);
            Clear(ReminderEmailText);
            Clear(LocalGuid);
            if not IsNullGuid(ReminderTerms."Reminder Attachment Text") then
                LocalGuid := ReminderTerms."Reminder Attachment Text";
            if not IsNullGuid(ReminderTerms."Reminder Email Text") then
                LocalGuid := ReminderTerms."Reminder Email Text";
            if IsNullGuid(LocalGuid) then
                LocalGuid := CreateGuid();
            if not ReminderAttachmentText.Get(LocalGuid, DefaultLanguageCode) then
                ReminderAttachmentText.SetDefaultContentForNewLanguage(LocalGuid, DefaultLanguageCode, Enum::"Reminder Text Source Type"::"Reminder Term", ReminderTerms.SystemId);
            if not ReminderEmailText.Get(LocalGuid, DefaultLanguageCode) then
                ReminderEmailText.SetDefaultContentForNewLanguage(LocalGuid, DefaultLanguageCode, Enum::"Reminder Text Source Type"::"Reminder Term", ReminderTerms.SystemId);
            if ReminderAttachmentText.Get(LocalGuid, DefaultLanguageCode) then begin
                ReminderAttachmentText."Inline Fee Description" := CopyStr(ReminderTerms."Note About Line Fee on Report", 1, 100);
                ReminderAttachmentText.Modify(true);
            end;
        until ReminderTerms.Next() = 0;
    end;

    internal procedure TransferReminderLevelLineFeeDescription()
    var
        ReminderLevel: Record "Reminder Level";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderEmailText: Record "Reminder Email Text";
        Language: Codeunit Language;
        LocalGuid: Guid;
        DefaultLanguageCode: Code[10];
    begin
        if ReminderLevel.IsEmpty() then
            exit;
        DefaultLanguageCode := Language.GetLanguageCode(Language.GetDefaultApplicationLanguageId());
        ReminderLevel.FindSet();
        repeat
            Clear(ReminderAttachmentText);
            Clear(ReminderEmailText);
            Clear(LocalGuid);
            if not IsNullGuid(ReminderLevel."Reminder Attachment Text") then
                LocalGuid := ReminderLevel."Reminder Attachment Text";
            if not IsNullGuid(ReminderLevel."Reminder Email Text") then
                LocalGuid := ReminderLevel."Reminder Email Text";
            if IsNullGuid(LocalGuid) then
                LocalGuid := CreateGuid();
            if not ReminderAttachmentText.Get(LocalGuid, DefaultLanguageCode) then
                ReminderAttachmentText.SetDefaultContentForNewLanguage(LocalGuid, DefaultLanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", ReminderLevel.SystemId);
            if not ReminderEmailText.Get(LocalGuid, DefaultLanguageCode) then
                ReminderEmailText.SetDefaultContentForNewLanguage(LocalGuid, DefaultLanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", ReminderLevel.SystemId);
            if ReminderAttachmentText.Get(LocalGuid, DefaultLanguageCode) then begin
                ReminderAttachmentText."Inline Fee Description" := CopyStr(ReminderLevel."Add. Fee per Line Description", 1, 100);
                ReminderAttachmentText.Modify(true);
            end;
        until ReminderLevel.Next() = 0;
    end;

    local procedure FindEmailSubject(var IssuedReminderHeader: Record "Issued Reminder Header"; var EmailSubject: Text[250]): Boolean
    var
        ReminderEmailText: Record "Reminder Email Text";
    begin
        if not GetReminderEmailText(IssuedReminderHeader, ReminderEmailText) then
            exit(false);

        EmailSubject := ReminderEmailText.Subject;
        SubstituteRelatedValues(EmailSubject, IssuedReminderHeader, IssuedReminderHeader.CalculateTotalIncludingVAT(), CopyStr(CompanyName, 1, 100));
        exit(true);
    end;

    local procedure ReplaceHTMLText(var IssuedReminderHeader: Record "Issued Reminder Header"; var HtmlContent: Text)
    var
        ReminderEmailText: Record "Reminder Email Text";
        BodyText: Text;
    begin
        ReminderEmailText.SetAutoCalcFields("Body Text");
        if GetReminderEmailText(IssuedReminderHeader, ReminderEmailText) then
            SelectEmailBodyText(ReminderEmailText, IssuedReminderHeader, BodyText)
        else
            SelectEmailBodyText(IssuedReminderHeader, BodyText);

        SubstituteRelatedValues(BodyText, IssuedReminderHeader, IssuedReminderHeader.CalculateTotalIncludingVAT(), CopyStr(CompanyName, 1, 100));
        HtmlContent := HtmlContent.Replace(ReplaceTextTok, BodyText);
    end;

    local procedure FindFileName(var IssuedReminderHeader: Record "Issued Reminder Header"; var Filename: Text; FileExtension: Text[30]): Boolean
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
    begin
        if not GetReminderAttachmentText(IssuedReminderHeader, ReminderAttachmentText) then
            exit(false);

        if ReminderAttachmentText."File Name" = '' then
            exit(false);

        Filename := ReminderAttachmentText."File Name" + FileExtension;
        SubstituteRelatedValues(Filename, IssuedReminderHeader, IssuedReminderHeader.CalculateTotalIncludingVAT(), CopyStr(CompanyName, 1, 100));
        Filename := Filename.Replace('/', '-');
        exit(true);
    end;

    local procedure GetReminderEmailText(var IssuedReminderHeader: Record "Issued Reminder Header"; var ReminderEmailText: Record "Reminder Email Text"): Boolean
    var
        ReminderLevel: Record "Reminder Level";
        ReminderTerms: Record "Reminder Terms";
        LanguageCode: Code[10];
    begin
        if (IssuedReminderHeader."Reminder Level" = 0) or (IssuedReminderHeader."Reminder Terms Code" = '') then
            exit(false);

        if not ReminderLevel.Get(IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level") then
            Error(ReminderLevelNotFoundErr, IssuedReminderHeader."Reminder Level", IssuedReminderHeader."Reminder Terms Code");

        LanguageCode := GetCustomerLanguageOrDefaultUserLanguage(IssuedReminderHeader."Customer No.");
        if ReminderEmailText.Get(ReminderLevel."Reminder Email Text", LanguageCode) then
            exit(true);

        if not ReminderTerms.Get(IssuedReminderHeader."Reminder Terms Code") then
            Error(ReminderTermNotFoundErr, IssuedReminderHeader."Reminder Terms Code");

        if ReminderEmailText.Get(ReminderTerms."Reminder Email Text", LanguageCode) then
            exit(true);

        exit(false);
    end;

    local procedure CalculateLineSpacingForBeginningText(var ReminderLine: Record "Reminder Line"; var ReminderAttachmentText: Record "Reminder Attachment Text"): Integer
    var
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
        LineSpacing: Integer;
    begin
        if ReminderLine.FindFirst() then begin
            ReminderAttachmentTextLine.SetRange(Id, ReminderAttachmentText.Id);
            ReminderAttachmentTextLine.SetRange("Language Code", ReminderAttachmentText."Language Code");
            ReminderAttachmentTextLine.SetRange(Position, ReminderAttachmentTextLine.Position::"Beginning Line");
            LineSpacing := ReminderLine."Line No." div (ReminderAttachmentTextLine.Count() + 2);
            if LineSpacing = 0 then
                Error(NoEnoughSpaceForTextErr);
        end else
            LineSpacing := 10000;

        exit(LineSpacing);
    end;

    local procedure CalculateLineSpacingForEndingText(var ReminderLine: Record "Reminder Line"; var ReminderLine2: Record "Reminder Line"; var ReminderAttachmentText: Record "Reminder Attachment Text"): Integer
    var
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
        LineSpacing: Integer;
    begin

        if ReminderLine2.Next() <> 0 then begin
            ReminderAttachmentTextLine.SetRange(Id, ReminderAttachmentText.Id);
            ReminderAttachmentTextLine.SetRange("Language Code", ReminderAttachmentText."Language Code");
            ReminderAttachmentTextLine.SetRange(Position, ReminderAttachmentTextLine.Position::"Ending Line");
            LineSpacing := (ReminderLine2."Line No." - ReminderLine."Line No.") div (ReminderAttachmentTextLine.Count() + 2);
            if LineSpacing = 0 then
                Error(NoEnoughSpaceForTextErr);
        end else
            LineSpacing := 10000;

        exit(LineSpacing);
    end;

    local procedure GetReminderAttachmentText(var IssuedReminderHeader: Record "Issued Reminder Header"; var ReminderAttachmentText: Record "Reminder Attachment Text"): Boolean
    var
        ReminderLevel: Record "Reminder Level";
        ReminderTerms: Record "Reminder Terms";
        LanguageCode: Code[10];
    begin
        if (IssuedReminderHeader."Reminder Level" = 0) or (IssuedReminderHeader."Reminder Terms Code" = '') then
            exit(false);

        if not ReminderLevel.Get(IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level") then
            Error(ReminderLevelNotFoundErr, IssuedReminderHeader."Reminder Level", IssuedReminderHeader."Reminder Terms Code");

        LanguageCode := GetCustomerLanguageOrDefaultUserLanguage(IssuedReminderHeader."Customer No.");
        if ReminderAttachmentText.Get(ReminderLevel."Reminder Attachment Text", LanguageCode) then
            exit(true);

        if not ReminderTerms.Get(IssuedReminderHeader."Reminder Terms Code") then
            Error(ReminderTermNotFoundErr, IssuedReminderHeader."Reminder Terms Code");

        if ReminderAttachmentText.Get(ReminderTerms."Reminder Attachment Text", LanguageCode) then
            exit(true);

        exit(false);
    end;

    local procedure StripHtmlTags(HtmlText: Text): Text
    var
        Regex: Codeunit Regex;
        TypeHelper: Codeunit "Type Helper";
    begin
        // Remove HTML tags using regex (more accurate than string manipulation)
        HtmlText := Regex.Replace(HtmlText, '<.*?>', '');

        // Decode HTML entities using framework utility
        HtmlText := TypeHelper.HtmlDecode(HtmlText);

        // Clean up whitespace
        HtmlText := HtmlText.Trim();
        while HtmlText.Contains('  ') do
            HtmlText := HtmlText.Replace('  ', ' ');

        exit(HtmlText);
    end;

    var
#if not CLEAN26
        FeatureIdTok: Label 'ReminderTermsCommunicationTexts', Locked = true;
#endif
        ReplaceTextTok: Label '==ReplaceText==', Locked = true;
        PDFFileExtensionTok: Label '.pdf', Locked = true;
        CommaSeparatedTok: Label '%1, %2', Locked = true;
        AppendixTextTok: Label '%1\\%2', Locked = true;
        ReminderLbl: Label 'Reminder';
        NoEnoughSpaceForTextErr: Label 'There is not enough space to insert the text.';
        LanguagesCustomerCommunicationsLbl: Label 'Attachments: %1\Emails: %2', Comment = '%1 = List of languages with attachment texts, %2 = List of languages with email texts';
        ReminderLevelNotFoundErr: Label 'Reminder Level %1 on Reminder Term %2 was not found.', Comment = '%1 = Reminder Level No., %2 = Reminder Term Code';
        ReminderTermNotFoundErr: Label 'Reminder Term %1 was not found.', Comment = '%1 = Reminder Term Code';
        MismatchLanguagesBetweenTermsAndLevelsMsg: Label 'The languages for the communications for the reminder terms and levels don''t match, which means that reminders won''t be personalized for some languages. Do you want to review the languages in level %1?', Comment = '%1 = List of affected reminder levels.';
        ExtensionMismatchLanguagesBetweenTermsAndLevelsMsg: Label 'There are differences among selected languages on levels also, so you might want to review those as well.';
        MismatchLanguagesBetweenLevelsMsg: Label 'The languages for the communications for the reminder levels don''t match, which means that reminders won''t be personalized for some languages. Do you want to review the languages before leaving this page?';

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnAfterDoSaveReportAsHTMLInTempBlob', '', true, true)]
    local procedure OnReplaceHTMLText(ReportID: Integer; var TempBlob: Codeunit "Temp Blob"; var RecordVariant: Variant)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        TypeHelper: Codeunit "Type Helper";
        RecordReference: RecordRef;
        ReadStream: InStream;
        WriteStream: OutStream;
        HtmlContent: Text;
        ReportIDExit: Boolean;
    begin
        if ReportID <> Report::Reminder then begin
            ReportIDExit := true;
            OnBeforeExitReportIDOnReplaceHTMLText(ReportID, RecordVariant, ReportIDExit);
            if ReportIDExit then
                exit;
        end;
        if not RecordVariant.IsRecordRef() then
            exit;

        RecordReference.GetTable(RecordVariant);
        if RecordReference.Number <> IssuedReminderHeader.RecordId.TableNo then
            exit;
        IssuedReminderHeader.Copy(RecordVariant);

        TempBlob.CreateInStream(ReadStream, TextEncoding::UTF8);
        TypeHelper.TryReadAsTextWithSeparator(ReadStream, TypeHelper.LFSeparator(), HtmlContent);
        Clear(ReadStream);
        Clear(TempBlob);

        ReplaceHTMLText(IssuedReminderHeader, HtmlContent);

        TempBlob.CreateOutStream(WriteStream, TextEncoding::UTF8);
        WriteStream.WriteText(HtmlContent);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeGetEmailSubject', '', true, true)]
    local procedure OnBeforeGetEmailSubject(PostedDocNo: Code[20]; EmailDocumentName: Text[250]; ReportUsage: Integer; var EmailSubject: Text[250]; var IsHandled: Boolean)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        if IsHandled or (EmailSubject <> '') then
            exit;

        if ReportUsage <> Enum::"Report Selection Usage"::Reminder.AsInteger() then
            exit;

        if EmailDocumentName <> ReportDistributionManagement.GetIssuedReminderDocTypeTxt() then
            exit;

        if not IssuedReminderHeader.Get(PostedDocNo) then
            exit;

        if FindEmailSubject(IssuedReminderHeader, EmailSubject) then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnGetFilename', '', false, false)]
    local procedure GetFilename(ReportID: Integer; Caption: Text[250]; ObjectPayload: JsonObject; FileExtension: Text[30]; ReportRecordRef: RecordRef; var Filename: Text; var Success: Boolean)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        if Success then
            exit;

        if ReportID <> Report::Reminder then
            exit;

        if (FileExtension <> PDFFileExtensionTok) or (not Filename.Contains(ReminderLbl)) then
            exit;

        if ReportRecordRef.Number <> IssuedReminderHeader.RecordId.TableNo then
            exit;
        ReportRecordRef.SetTable(IssuedReminderHeader);

        if FindFileName(IssuedReminderHeader, Filename, FileExtension) then
            Success := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeGetAttachmentFileName', '', false, false)]
    local procedure OnBeforeGetAttachmentFileName(PostedDocNo: Code[20]; ReportUsage: Integer; var AttachmentFileName: Text[250])
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        if ReportUsage <> "Report Selection Usage"::Reminder.AsInteger() then
            exit;

        if not IssuedReminderHeader.Get(PostedDocNo) then
            exit;

        if not FindFileName(IssuedReminderHeader, AttachmentFileName, PDFFileExtensionTok) then
            exit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExitReportIDOnReplaceHTMLText(ReportID: Integer; var RecordVariant: Variant; var ReportIDExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSubstituteRelatedValues(var BodyTxt: Text; var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
    end;
}