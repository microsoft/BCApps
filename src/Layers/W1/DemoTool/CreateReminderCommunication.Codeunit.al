codeunit 101296 "Create Reminder Communication"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
        Language: Codeunit Language;
    begin
        DemoDataSetup.Get();
        FirstLevelGuid := CreateGuid();
        SecondLevelGuid := CreateGuid();
        ThirdLevelGuid := CreateGuid();

        InsertReminderLevelsCommunications('ENU');
        UpdateReminderLevel(DemoDataSetup.DomesticCode(), 1, FirstLevelGuid);
        UpdateReminderLevel(DemoDataSetup.DomesticCode(), 2, SecondLevelGuid);
        UpdateReminderLevel(DemoDataSetup.DomesticCode(), 3, ThirdLevelGuid);
        InsertReminderTermCommunications(DemoDataSetup.ForeignCode(), Language.GetLanguageCode(Language.GetDefaultApplicationLanguageId()));
    end;

    local procedure InsertReminderLevelsCommunications(LanguageCode: Code[10])
    begin
        InsertReminderAttachmentText(FirstLevelGuid, LanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", AttachmentEndingLineFirstLevelLbl);
        InsertReminderEmailText(FirstLevelGuid, LanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", EmailBodyFirstLevelLbl);

        InsertReminderAttachmentText(SecondLevelGuid, LanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", AttachmentEndingLineSecondLevelLbl);
        InsertReminderEmailText(SecondLevelGuid, LanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", EmailBodySecondLevelLbl);

        InsertReminderAttachmentText(ThirdLevelGuid, LanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", AttachmentEndingLineThirdLevelLbl);
        InsertReminderEmailText(ThirdLevelGuid, LanguageCode, Enum::"Reminder Text Source Type"::"Reminder Level", EmailBodyThirdLevelLbl);
    end;

    local procedure UpdateReminderLevel(Code: Code[10]; Level: Integer; SelectedID: Guid)
    var
        ReminderLevel: Record "Reminder Level";
    begin
        ReminderLevel.Get(Code, Level);
        ReminderLevel."Reminder Attachment Text" := SelectedId;
        ReminderLevel."Reminder Email Text" := SelectedId;
        ReminderLevel.Modify(true);
    end;

    local procedure InsertReminderTermCommunications(ReminderTermsCode: Code[10]; LanguageCode: Code[10])
    var
        SelectedID: Guid;
    begin
        SelectedID := CreateGuid();
        InsertReminderAttachmentText(SelectedID, LanguageCode, Enum::"Reminder Text Source Type"::"Reminder Term", AttachmentEndingLineFirstLevelLbl);
        InsertReminderEmailText(SelectedID, LanguageCode, Enum::"Reminder Text Source Type"::"Reminder Term", EmailBodyFirstLevelLbl);
        UpdateReminderTerms(ReminderTermsCode, SelectedID);
    end;

    local procedure UpdateReminderTerms(Code: Code[10]; SelectedID: Guid)
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        ReminderTerms.Get(Code);
        ReminderTerms."Reminder Attachment Text" := SelectedId;
        ReminderTerms."Reminder Email Text" := SelectedId;
        ReminderTerms.Modify(true);
    end;

    local procedure InsertReminderAttachmentText(SelectedID: Guid; LanguageCode: Code[10]; SourceType: Enum "Reminder Text Source Type"; EndingLineText: Text[100])
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
        ReminderAttachmentTextLine2: Record "Reminder Attachment Text Line";
    begin
        ReminderAttachmentText.ID := SelectedID;
        ReminderAttachmentText."Language Code" := LanguageCode;
        ReminderAttachmentText.Validate("Source Type", SourceType);
        ReminderAttachmentText.Validate("File Name", AttachmentFileNameLbl);
        ReminderAttachmentText.Validate("Inline Fee Description", AttachmentInlineFeeDescriptionLbl);
        ReminderAttachmentText.Insert(true);

        ReminderAttachmentTextLine.Id := SelectedID;
        ReminderAttachmentTextLine."Language Code" := LanguageCode;
        ReminderAttachmentTextLine.Position := ReminderAttachmentTextLine.Position::"Ending Line";
        ReminderAttachmentTextLine.Text := EndingLineText;
        ReminderAttachmentTextLine2.SetRange(Id, SelectedID);
        ReminderAttachmentTextLine2.SetRange("Language Code", LanguageCode);
        ReminderAttachmentTextLine2.SetRange(Position, ReminderAttachmentTextLine2.Position::"Ending Line");
        if ReminderAttachmentTextLine2.FindLast() then
            ReminderAttachmentTextLine."Line No." := ReminderAttachmentTextLine2."Line No." + 10000
        else
            ReminderAttachmentTextLine."Line No." := 10000;
        ReminderAttachmentTextLine.Insert(true);
    end;

    local procedure InsertReminderEmailText(SelectedID: Guid; LanguageCode: Code[10]; SourceType: Enum "Reminder Text Source Type"; BodyText: Text)
    var
        ReminderEmailText: Record "Reminder Email Text";
    begin
        ReminderEmailText.Id := SelectedID;
        ReminderEmailText."Language Code" := LanguageCode;
        ReminderEmailText.Validate("Source Type", SourceType);
        ReminderEmailText.Validate("Subject", EmailSubjectLbl);
        ReminderEmailText.Validate("Greeting", EmailGreetingLbl);
        ReminderEmailText.Validate("Closing", EmailClosingLbl);
        ReminderEmailText.Insert(true);
        ReminderEmailText.SetBodyText(BodyText);
    end;

    var
        FirstLevelGuid: Guid;
        SecondLevelGuid: Guid;
        ThirdLevelGuid: Guid;
        AttachmentFileNameLbl: Label 'Reminder', MaxLength = 100;
        AttachmentInlineFeeDescriptionLbl: Label 'Additional fee.', MaxLength = 100;
        AttachmentEndingLineFirstLevelLbl: Label 'Please remit your payment of %7 as soon as possible.', Comment = '%7 = The total amount of the reminder', MaxLength = 100;
        AttachmentEndingLineSecondLevelLbl: Label 'Please remit your payment of %7 as soon as possible to avoid further fees and charges.', Comment = '%7 = The total amount of the reminder', MaxLength = 100;
        AttachmentEndingLineThirdLevelLbl: Label 'This is reminder number %8. Your account has now been sent to our attorney.', Comment = '%8 = The reminder number', MaxLength = 100;
        EmailSubjectLbl: Label 'Issued Reminder', MaxLength = 128;
        EmailGreetingLbl: Label 'Dear Customer,', MaxLength = 128;
        EmailBodyFirstLevelLbl: Label 'You are receiving this email to formally notify you that a payment you owe is past due. The payment was due on %1. Enclosed is a copy of the invoice with the details of the remaining amount. If you have already made the payment, please disregard this email. Thank you for your business.', Comment = '%1 = The due date';
        EmailBodySecondLevelLbl: Label 'This is a second reminder that a payment you own, which was due on %1, remains unpaid. An invoice with the outstanding amount is attached to this message. If you have already made the payment, please disregard this email. If not, we urge you to remit payment to avoid additional fees and charges. We value your business and hope to resolve this matter promptly.', Comment = '%1 = The due date';
        EmailBodyThirdLevelLbl: Label 'This is your third reminder that a payment due on %1 is still outstanding. The attached invoice provides details of the remaining amount. If you have settled this payment, please ignore this email. However, if the payment has''t been made, please be aware that your account has been sent to our attorney for further action. We appreciate your immediate attention to this matter. Thank you for your business.', Comment = '%1 = The due date';
        EmailClosingLbl: Label 'Sincerely,', MaxLength = 128;
}