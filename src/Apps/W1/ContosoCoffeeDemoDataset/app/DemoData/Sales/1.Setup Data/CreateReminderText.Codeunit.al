// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Sales;

using Microsoft.DemoTool;
using Microsoft.DemoTool.Helpers;
using Microsoft.Sales.Reminder;

codeunit 5268 "Create Reminder Text"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        CreateReminderTerms: Codeunit "Create Reminder Terms";
        CreateReminderLevel: Codeunit "Create Reminder Level";
        ContosoLanguage: Codeunit "Contoso Language";
        ContosoReminder: Codeunit "Contoso Reminder";
        LanguageCode: Code[10];
    begin
        ContosoCoffeeDemoDataSetup.Get();
        LanguageCode := ContosoLanguage.GetLanguageCode(ContosoCoffeeDemoDataSetup."Country/Region Code");

        InsertReminderCommunication(ContosoReminder, CreateReminderTerms.Domestic(), CreateReminderLevel.DomesticLevel1(), LanguageCode, DomesticPmtReminderLbl, '', EmailBodyLevel1Lbl);
        InsertReminderCommunication(ContosoReminder, CreateReminderTerms.Domestic(), CreateReminderLevel.DomesticLevel2(), LanguageCode, BalanceLbl, AccountAgencyLbl, EmailBodyLevel2Lbl);
        InsertReminderCommunication(ContosoReminder, CreateReminderTerms.Domestic(), CreateReminderLevel.DomesticLevel3(), LanguageCode, ReminderLbl, AccountAttorneyLbl, EmailBodyLevel3Lbl);

        InsertReminderCommunication(ContosoReminder, CreateReminderTerms.Foreign(), CreateReminderLevel.ForeignLevel1(), LanguageCode, DomesticPmtReminderLbl, '', EmailBodyLevel1Lbl);
        InsertReminderCommunication(ContosoReminder, CreateReminderTerms.Foreign(), CreateReminderLevel.ForeignLevel2(), LanguageCode, BalanceLbl, AccountAgencyLbl, EmailBodyLevel2Lbl);
        InsertReminderCommunication(ContosoReminder, CreateReminderTerms.Foreign(), CreateReminderLevel.ForeignLevel3(), LanguageCode, ReminderLbl, AccountAttorneyLbl, EmailBodyLevel3Lbl);
    end;

    local procedure InsertReminderCommunication(var ContosoReminder: Codeunit "Contoso Reminder"; ReminderTermsCode: Code[10]; ReminderLevelNo: Integer; LanguageCode: Code[10]; FirstEndingLine: Text[100]; SecondEndingLine: Text[100]; EmailBody: Text)
    var
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
        ReminderLevel: Record "Reminder Level";
        ReminderGuid: Guid;
    begin
        ReminderGuid := CreateGuid();
        ContosoReminder.InsertReminderAttachText(ReminderGuid, ReminderTermsCode, ReminderLevelNo, LanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", AttachmentFileNameLbl, '', '', FirstEndingLine);
        ReminderLevel.Get(ReminderTermsCode, ReminderLevelNo);
        ReminderGuid := ReminderLevel."Reminder Attachment Text";
        ContosoReminder.InsertReminderAttachTextLine(ReminderGuid, LanguageCode, ReminderAttachmentTextLine.Position::"Ending Line", 20000, SecondEndingLine);
        ContosoReminder.InsertReminderEmailText(ReminderTermsCode, ReminderLevelNo, LanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", EmailSubjectLbl, EmailGreetingLbl, EmailBody, EmailClosingLbl);
    end;

    var
        DomesticPmtReminderLbl: Label 'Please remit your payment of %7 as soon as possible.', MaxLength = 100, Comment = '%7 Document Type';
        BalanceLbl: Label 'If the balance is not received within 10 days,', MaxLength = 100;
        AccountAgencyLbl: Label 'your account will be sent to a collection agency.', MaxLength = 100;
        ReminderLbl: Label 'This is reminder number %8.', MaxLength = 100, Comment = '%8 No. of Reminders';
        AccountAttorneyLbl: Label 'Your account has now been sent to our attorney.', MaxLength = 100;
        AttachmentFileNameLbl: Label 'Reminder', MaxLength = 100;
        EmailSubjectLbl: Label 'Issued Reminder', MaxLength = 128;
        EmailGreetingLbl: Label 'Dear Customer,', MaxLength = 128;
        EmailClosingLbl: Label 'Sincerely,', MaxLength = 128;
        EmailBodyLevel1Lbl: Label 'Please remit your payment as soon as possible. The payment was due on %1. If you have already made the payment, please disregard this email. Thank you for your business.', Comment = '%1 = Due date';
        EmailBodyLevel2Lbl: Label 'This is a second reminder that a payment due on %1 remains unpaid. Please remit payment to avoid further fees and charges. If you have already made the payment, please disregard this email.', Comment = '%1 = Due date';
        EmailBodyLevel3Lbl: Label 'This is reminder number %8. The payment due on %1 remains unpaid and your account has now been sent to our attorney.', Comment = '%1 = Due date, %8 = Reminder level';
}
