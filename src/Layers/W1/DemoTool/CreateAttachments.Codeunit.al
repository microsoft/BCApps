codeunit 101562 "Create Attachments"
{

    trigger OnRun()
    begin
    end;

    var
        Attachment: Record Attachment;

    procedure InsertData("File Name": Text[260]; "File Extension": Text[260]; "Read Only": Boolean) "Attachment No.": Integer
    var
        NextAttachmentNo: Integer;
    begin
        if Attachment.FindLast() then
            NextAttachmentNo := Attachment."No." + 1
        else
            NextAttachmentNo := 1;

        Attachment.Init();
        Attachment."No." := NextAttachmentNo;
        Attachment."Attachment File".Import("File Name" + '.' + "File Extension");
        Attachment."File Extension" := "File Extension";
        Attachment."Read Only" := "Read Only";
        Attachment.Insert();
        exit(Attachment."No.");
    end;
}

