codeunit 101596 "Create Interact. Templ. Lang."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertFileTemplatesForLang(XENU);
        InsertData(XGOLF, XENU, XHTML);

        if DemoDataSetup."Language Code" <> XENU then
            InsertFileTemplatesForLang(DemoDataSetup."Language Code");
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        XABSTRACT: Label 'ABSTRACT';
        XDOC: Label 'DOC';
        XBUS: Label 'BUS';
        XGOLF: Label 'GOLF';
        XMEMO: Label 'MEMO';
        XENU: Label 'ENU';
        XHTML: Label 'HTML';

    procedure InsertData(InteractionTemplateCode: Code[10]; LanguageCode: Code[10]; FileExtension: Text[250])
    var
        InsertInteractionTmplLanguage: Boolean;
        CustomReportLayoutCode: Code[20];
        AttachmentNo: Integer;
    begin
        if LowerCase(FileExtension) = 'html' then
            InsertInteractionTmplLanguage :=
              InsertCustomAttachment(FileExtension, AttachmentNo, CustomReportLayoutCode)
        else
            InsertInteractionTmplLanguage :=
              InsertFileAttachment(InteractionTemplateCode, LanguageCode, FileExtension, AttachmentNo);

        if InsertInteractionTmplLanguage then
            InsertDataWithAttachment(InteractionTemplateCode, LanguageCode, AttachmentNo, CustomReportLayoutCode);
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        InsertDataWithoutAttachment(XABSTRACT, XENU);
        InsertDataWithoutAttachment(XBUS, XENU);
        InsertData(XGOLF, XENU, XHTML);

        if DemoDataSetup."Language Code" <> XENU then begin
            InsertDataWithoutAttachment(XABSTRACT, DemoDataSetup."Language Code");
            InsertDataWithoutAttachment(XBUS, DemoDataSetup."Language Code");
        end;
    end;

    local procedure InsertDataWithoutAttachment(InteractionTemplateCode: Code[10]; LanguageCode: Code[10])
    begin
        InteractionTmplLanguage.Init();
        InteractionTmplLanguage."Interaction Template Code" := InteractionTemplateCode;
        InteractionTmplLanguage."Language Code" := LanguageCode;
        InteractionTmplLanguage.Insert();
    end;

    local procedure GetNextAttachmentNo(): Integer
    var
        Attachment: Record Attachment;
    begin
        if Attachment.FindLast() then
            exit(Attachment."No." + 1);
        exit(1);
    end;

    local procedure InsertAttachment(var Attachment: Record Attachment; FileExtension: Text[250])
    begin
        Attachment.Init();
        Attachment."No." := GetNextAttachmentNo();
        Attachment."File Extension" := FileExtension;
        Attachment.Insert();
    end;

    local procedure InsertCustomAttachment(FileExtension: Text[250]; var AttachmentNo: Integer; var CustomReportLayoutCode: Code[20]): Boolean
    var
        CustomReportLayout: Record "Custom Report Layout";
        Attachment: Record Attachment;
    begin
        CustomReportLayout.SetRange("Report ID", REPORT::"Email Merge");
        if CustomReportLayout.FindFirst() then begin
            InsertAttachment(Attachment, FileExtension);
            Attachment.WriteHTMLCustomLayoutAttachment('', CustomReportLayout.Code);
            AttachmentNo := Attachment."No.";
            CustomReportLayoutCode := CustomReportLayout.Code;
            exit(true);
        end;

        exit(false);
    end;

    local procedure InsertFileAttachment(InteractionTemplateCode: Code[10]; LanguageCode: Code[10]; FileExtension: Text[250]; var AttachmentNo: Integer): Boolean
    var
        Attachment: Record Attachment;
        FileName: Text;
    begin
        FileName := InteractionTemplateCode;
        if LanguageCode <> XENU then
            FileName := FileName + ' ' + LanguageCode;
        FileName := DemoDataSetup."Path to Picture Folder" + FileName + '.' + FileExtension;

        if Exists(FileName) then begin
            InsertAttachment(Attachment, FileExtension);
            Attachment."Attachment File".Import(FileName);
            Attachment.Modify();
            AttachmentNo := Attachment."No.";
            exit(true);
        end;

        exit(false);
    end;

    local procedure InsertDataWithAttachment(InteractionTemplateCode: Code[10]; LanguageCode: Code[10]; AttachmentNo: Integer; CustomReportLayoutCode: Code[20])
    begin
        InsertDataWithoutAttachment(InteractionTemplateCode, LanguageCode);
        InteractionTmplLanguage.Validate("Attachment No.", AttachmentNo);
        if CustomReportLayoutCode <> '' then
            InteractionTmplLanguage.Validate("Custom Layout Code", CustomReportLayoutCode);
        InteractionTmplLanguage.Modify();
    end;

    local procedure InsertFileTemplatesForLang(LanguageCode: Code[10])
    begin
        InsertData(XABSTRACT, LanguageCode, XDOC);
        InsertData(XBUS, LanguageCode, XDOC);
        InsertData(XMEMO, LanguageCode, XDOC);
    end;
}

