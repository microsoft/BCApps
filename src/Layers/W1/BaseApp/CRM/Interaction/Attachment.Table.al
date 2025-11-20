// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using System.Environment;
using System.IO;
using System.Utilities;

table 5062 Attachment
{
    Caption = 'Attachment';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; "Attachment File"; BLOB)
        {
            Caption = 'Attachment File';
        }
        field(3; "Storage Type"; Enum "Attachment Storage Type")
        {
            Caption = 'Storage Type';
        }
        field(4; "Storage Pointer"; Text[250])
        {
            Caption = 'Storage Pointer';
        }
        field(5; "File Extension"; Text[250])
        {
            Caption = 'File Extension';
        }
        field(6; "Read Only"; Boolean)
        {
            Caption = 'Read Only';
        }
        field(7; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
        }
        field(8; "Last Time Modified"; Time)
        {
            Caption = 'Last Time Modified';
        }
        field(13; "Merge Source"; BLOB)
        {
            Caption = 'Merge Source';
        }
        field(14; "Email Message ID"; BLOB)
        {
            Caption = 'Email Message ID';
        }
        field(15; "Email Entry ID"; BLOB)
        {
            Caption = 'Email Entry ID';
        }
        field(16; "Email Message Checksum"; Integer)
        {
            Caption = 'Email Message Checksum';
        }
        field(17; "Email Message Url"; BLOB)
        {
            Caption = 'Email Message Url';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Email Message Checksum")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        Attachment2: Record Attachment;
        NextAttachmentNo: Integer;
    begin
        "Last Date Modified" := Today;
        "Last Time Modified" := Time;

        Attachment2.LockTable();
        if Attachment2.FindLast() then
            NextAttachmentNo := Attachment2."No." + 1
        else
            NextAttachmentNo := 1;

        "No." := NextAttachmentNo;

        RMSetup.Get();
        "Storage Type" := RMSetup."Attachment Storage Type";
        if "Storage Type" = "Storage Type"::"Disk File" then begin
            RMSetup.TestField("Attachment Storage Location");
            "Storage Pointer" := RMSetup."Attachment Storage Location";
        end;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        "Last Time Modified" := Time;
    end;

    var
        RMSetup: Record "Marketing Setup";
        FileManagement: Codeunit "File Management";
        AttachmentManagement: Codeunit AttachmentManagement;
        ClientTypeManagement: Codeunit "Client Type Management";

#pragma warning disable AA0074
        Text002: Label 'The attachment is empty.';
        Text005: Label 'Export Attachment';
        Text006: Label 'Import Attachment';
        Text007: Label 'All Files (*.*)|*.*';
#pragma warning disable AA0470
        Text008: Label 'Error during copying file: %1.';
        Text009: Label 'Do you want to remove %1?';
#pragma warning restore AA0470
        Text010: Label 'External file could not be removed.';
#pragma warning restore AA0074
        AttachmentImportQst: Label 'Do you want to import attachment?';
        AttachmentExportQst: Label 'Do you want to export attachment to view or edit it externaly?';

    procedure OpenAttachment(Caption: Text[260]; IsTemporary: Boolean; LanguageCode: Code[10])
    var
        SegmentLine: Record "Segment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenAttachment(Rec, Caption, IsTemporary, LanguageCode, IsHandled);
        if IsHandled then
            exit;

        if IsHTML() then begin
            SegmentLine.Init();
            SegmentLine."Language Code" := LanguageCode;
            SegmentLine.Date := WorkDate();
            PreviewHTMLContent(SegmentLine);
            exit;
        end;

        if "Storage Type" = "Storage Type"::Embedded then begin
            CalcFields("Attachment File");
            if not "Attachment File".HasValue() then
                Error(Text002);
        end;

        if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Web, CLIENTTYPE::Tablet, CLIENTTYPE::Phone, CLIENTTYPE::Desktop] then
            ProcessWebAttachment(Caption + '.' + "File Extension")
    end;

    procedure OpenAttachment(var SegmentLine: Record "Segment Line"; WordCaption: Text)
    begin
        if IsHTML() then begin
            PreviewHTMLContent(SegmentLine);
            exit;
        end;

        if "Storage Type" = "Storage Type"::Embedded then
            CalcFields("Attachment File");

        if SegmentLine."Word Template Code" = '' then
            ProcessWebAttachment(WordCaption + '.' + "File Extension");
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::Attachment, 'r')]
    procedure InsertRecord()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if not Insert() then begin
            SequenceNoMgt.RebaseSeqNo(DATABASE::Attachment);
            "No." := SequenceNoMgt.GetNextSeqNo(DATABASE::Attachment);
            Insert();
        end;
    end;

    procedure ShowAttachment(var SegLine: Record "Segment Line"; WordCaption: Text)
    var
        WordTemplateInteractions: Codeunit "Word Template Interactions";
        IsHandled: Boolean;
    begin
        OnBeforeShowAttachment(SegLine, WordCaption, IsHandled, Rec);
        if IsHandled then
            exit;

        if IsHTML() then begin
            PreviewHTMLContent(SegLine);
            exit;
        end;

        if "Storage Type" = "Storage Type"::Embedded then
            CalcFields("Attachment File");

        OnShowAttachmentOnAfterCalcAttachmentFile(Rec);

        if WordTemplateInteractions.IsWordDocumentExtension("File Extension") then
            WordTemplateInteractions.RunMergedDocument(SegLine, Rec)
        else
            ProcessWebAttachment(WordCaption + '.' + "File Extension");
    end;

    local procedure PreviewHTMLContent(SegmentLine: Record "Segment Line")
    var
        ContentPreview: Page "Content Preview";
    begin
        ContentPreview.SetContent(AttachmentManagement.LoadHTMLContent(Rec, SegmentLine));
        ContentPreview.RunModal();
    end;

    [Scope('OnPrem')]
    procedure ExportAttachmentToClientFile(var ExportToFile: Text): Boolean
    var
        FileFilter: Text;
        ServerFileName: Text;
        Path: Text;
        Success: Boolean;
    begin
        RMSetup.Get();
        if RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::"Disk File" then
            RMSetup.TestField("Attachment Storage Location");

        ServerFileName := FileManagement.ServerTempFileName("File Extension");
        ExportAttachmentToServerFile(ServerFileName);

        Path := FileManagement.Magicpath();
        if ExportToFile = '' then
            Path := '';

        FileFilter := UpperCase("File Extension") + ' (*.' + "File Extension" + ')|*.' + "File Extension";
        Success := Download(ServerFileName, Text005, Path, FileFilter, ExportToFile);
        FileManagement.DeleteServerFile(ServerFileName);
        exit(Success);
    end;

    [Scope('OnPrem')]
    procedure ImportAttachmentFromClientFile(ImportFromFile: Text; IsTemporary: Boolean; IsInherited: Boolean): Boolean
    var
        FileName: Text;
        ServerFileName: Text;
        NewAttachmentNo: Integer;
    begin
        ClearLastError();
        if IsTemporary then
            exit(ImportTemporaryAttachmentFromClientFile(ImportFromFile));

        TestField("Read Only", false);
        RMSetup.Get();
        if RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::"Disk File" then
            RMSetup.TestField("Attachment Storage Location");

        if IsInherited then begin
            NewAttachmentNo := AttachmentManagement.InsertAttachment("No.");
            Get(NewAttachmentNo);
        end else
            if "No." = 0 then
                NewAttachmentNo := AttachmentManagement.InsertAttachment(0)
            else
                NewAttachmentNo := "No.";
        Get(NewAttachmentNo);

        // passing to UPLOAD function when only server path is specified, not ALSO the file name,
        // then function updates the server file path with the actual client name
        ServerFileName := TemporaryPath;
        FileName := ImportFromFile;
        if not Upload(Text006, '', Text007, FileName, ServerFileName) then begin
            if GetLastErrorText <> '' then
                Error(Text008, GetLastErrorText);
            exit(false);
        end;

        exit(ImportAttachmentFromServerFile(ServerFileName, false, true));
    end;

    local procedure ImportTemporaryAttachmentFromClientFile(ImportFromFile: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
    begin
        FileName := FileManagement.BLOBImport(TempBlob, ImportFromFile);

        if FileName <> '' then begin
            SetAttachmentFileFromBlob(TempBlob);
            "Storage Type" := "Storage Type"::Embedded;
            "Storage Pointer" := '';
            "File Extension" := CopyStr(UpperCase(FileManagement.GetExtension(FileName)), 1, 250);
            Modify();
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ExportAttachmentToServerFile(var ExportToFile: Text) Result: Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportAttachmentToServerFile(Rec, ExportToFile, Result, IsHandled);
        if IsHandled then
            exit(Result);

        // This function assumes that CALCFIELDS on the attachment field has been called before
        RMSetup.Get();
        if RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::"Disk File" then
            RMSetup.TestField("Attachment Storage Location");

        case "Storage Type" of
            "Storage Type"::Embedded:
                begin
                    if "Attachment File".HasValue() then begin
                        TempBlob.FromRecord(Rec, FieldNo("Attachment File"));
                        if ExportToFile = '' then
                            ExportToFile := FileManagement.ServerTempFileName("File Extension");
                        FileManagement.BLOBExportToServerFile(TempBlob, ExportToFile); // export BLOB to file on server (UNC location also)
                        exit(true);
                    end;
                    exit(false);
                end;
            "Storage Type"::"Disk File":
                begin
                    if ExportToFile = '' then
                        ExportToFile := TemporaryPath + FileManagement.GetFileName(ConstDiskFileName());
                    FileManagement.CopyServerFile(GetServerFileName(ConstDiskFileName()), ExportToFile, false); // Copy from server location to another location (UNC location also)
                    exit(true);
                end;
        end;

        exit(false);
    end;

    /// <summary>
    /// Export the Attachment to the TempBlob Codeunit.
    /// </summary>
    /// <param name="TempBlob"></param>
    /// <returns>true if a value attachment is return in the TempBlob parameter; otherwise false</returns>
    procedure ExportAttachmentToTempBlob(var TempBlob: Codeunit "Temp Blob") Result: Boolean
    begin
        RMSetup.Get();
        if RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::"Disk File" then
            RMSetup.TestField("Attachment Storage Location");

        case "Storage Type" of
            "Storage Type"::Embedded:
                begin
                    if "Attachment File".HasValue() then begin
                        TempBlob.FromRecord(Rec, FieldNo("Attachment File"));
                        exit(true);
                    end;
                    exit(false);
                end;
            "Storage Type"::"Disk File":
                begin
                    FileManagement.BLOBImportFromServerFile(TempBlob, GetServerFileName(ConstDiskFileName()));
                    exit(true);
                end;
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ImportAttachmentFromServerFile(ImportFromFile: Text; IsTemporary: Boolean; Overwrite: Boolean) Result: Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        FileExt: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeImportAttachmentFromServerFile(Rec, ImportFromFile, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if IsTemporary then begin
            ImportTemporaryAttachmentFromServerFile(ImportFromFile);
            exit(true);
        end;

        if not Overwrite then
            TestField("Read Only", false);

        RMSetup.Get();
        if RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::"Disk File" then
            RMSetup.TestField("Attachment Storage Location");

        case RMSetup."Attachment Storage Type" of
            RMSetup."Attachment Storage Type"::Embedded:
                begin
                    FileManagement.BLOBImportFromServerFile(TempBlob, ImportFromFile); // Copy from file on server (UNC location also)
                    SetAttachmentFileFromBlob(TempBlob);
                    "Storage Type" := "Storage Type"::Embedded;
                    "Storage Pointer" := '';
                    FileExt := CopyStr(FileManagement.GetExtension(ImportFromFile), 1, 250);
                    if FileExt <> '' then
                        "File Extension" := FileExt;
                    Modify(true);
                    exit(true);
                end;
            "Storage Type"::"Disk File":
                begin
                    "Storage Type" := "Storage Type"::"Disk File";
                    "Storage Pointer" := RMSetup."Attachment Storage Location";
                    FileExt := CopyStr(FileManagement.GetExtension(ImportFromFile), 1, 250);
                    if FileExt <> '' then
                        "File Extension" := FileExt;
                    FileManagement.CopyServerFile(ImportFromFile, ConstDiskFileName(), Overwrite); // Copy from UNC location to another UNC location
                    Modify(true);
                    exit(true);
                end;
        end;

        exit(false);
    end;

    internal procedure ImportAttachmentFromStream(InStream: InStream; FileExtension: Text) NewattachmentNo: Integer
    begin
        SetAttachmentFileFromStream(InStream);
        "Storage Type" := "Storage Type"::Embedded;
        "Storage Pointer" := '';
        "File Extension" := CopyStr(FileExtension, 1, 250);
        Insert(true);

        NewattachmentNo := "No.";
    end;

    local procedure ImportTemporaryAttachmentFromServerFile(ImportFromFile: Text)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        FileManagement.BLOBImportFromServerFile(TempBlob, ImportFromFile);
        SetAttachmentFileFromBlob(TempBlob);
        "Storage Type" := "Storage Type"::Embedded;
        "Storage Pointer" := '';
        "File Extension" := CopyStr(UpperCase(FileManagement.GetExtension(ImportFromFile)), 1, 250);
    end;

    [Scope('OnPrem')]
    procedure RemoveAttachment(Prompt: Boolean) DeleteOK: Boolean
    var
        DeleteYesNo: Boolean;
    begin
        DeleteOK := false;
        DeleteYesNo := true;
        if Prompt then
            if not Confirm(
                 Text009, false, TableCaption)
            then
                DeleteYesNo := false;

        if DeleteYesNo then begin
            if "Storage Type" = "Storage Type"::"Disk File" then
                if not FileManagement.DeleteServerFile(ConstDiskFileName()) then
                    Message(Text010);
            Delete(true);
            DeleteOK := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure WizEmbeddAttachment(FromAttachment: Record Attachment)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWizEmbeddAttachment(Rec, FromAttachment, IsHandled);
        if IsHandled then
            exit;

        Rec := FromAttachment;
        "No." := 0;
        "Storage Type" := "Storage Type"::Embedded;
        FromAttachment.TestField("No.");
        case FromAttachment."Storage Type" of
            FromAttachment."Storage Type"::"Disk File":
                ImportAttachmentFromServerFile(FromAttachment.ConstDiskFileName(), true, false);
            FromAttachment."Storage Type"::Embedded:
                begin
                    FromAttachment.CalcFields("Attachment File");
                    if FromAttachment."Attachment File".HasValue() then
                        "Attachment File" := FromAttachment."Attachment File";
                end;
        end;
    end;

    procedure WizSaveAttachment()
    var
        Attachment2: Record Attachment;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWizSaveAttachment(Rec, IsHandled);
        if IsHandled then
            exit;

        RMSetup.Get();
        if RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::Embedded then begin
            "Storage Pointer" := '';
            exit;
        end;

        "Storage Pointer" := RMSetup."Attachment Storage Location";

        CopyAttachmentAsFile(Rec, Attachment2);

        Clear(Rec);
        Rec := Attachment2;
    end;

    procedure ConstDiskFileName() DiskFileName: Text
    begin
        OnBeforeConstDiskFileName(Rec, DiskFileName);
        if DiskFileName = '' then
            DiskFileName := "Storage Pointer" + '\' + Format("No.") + '.' + "File Extension";
    end;

    local procedure CopyAttachmentAsFile(var FromAttachment: Record Attachment; var ToAttachment: Record Attachment)
    begin
        ToAttachment."No." := FromAttachment."No.";
        ToAttachment."Storage Type" := ToAttachment."Storage Type"::"Disk File";
        ToAttachment."Storage Pointer" := RMSetup."Attachment Storage Location";
        ToAttachment."Attachment File" := FromAttachment."Attachment File";
        ToAttachment."File Extension" := FromAttachment."File Extension";
        ToAttachment."Read Only" := FromAttachment."Read Only";
        ToAttachment."Last Date Modified" := FromAttachment."Last Date Modified";
        ToAttachment."Last Time Modified" := FromAttachment."Last Time Modified";

        OnAfterCopyAttachmentAsFile(FromAttachment, ToAttachment);
    end;

    procedure LinkToMessage(MessageID: Text; EntryID: Text; RunTrigger: Boolean)
    begin
        "Storage Type" := "Storage Type"::"Exchange Storage";
        "Read Only" := true;

        SetMessageID(MessageID);
        SetEntryID(EntryID);

        Modify(RunTrigger);
    end;

    procedure Checksum(MessageID: Text) ChecksumValue: Integer
    var
        CharNo: Integer;
        DecValue: Decimal;
        MaxInteger: Integer;
    begin
        Randomize(1);
        MaxInteger := 2147483647;

        for CharNo := 1 to StrLen(MessageID) do
            DecValue := (DecValue + (((MessageID[CharNo] mod 43) + 1) * Random((MaxInteger div 44)))) mod MaxInteger;
        ChecksumValue := DecValue;
    end;

    procedure GetMessageID() Return: Text
    var
        InStream: InStream;
    begin
        CalcFields("Email Message ID");
        "Email Message ID".CreateInStream(InStream);
        InStream.ReadText(Return);
    end;

    procedure SetMessageID(MessageID: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Email Message ID");
        "Email Message ID".CreateOutStream(OutStream);
        OutStream.WriteText(MessageID);
        "Email Message Checksum" := Checksum(MessageID);
    end;

    procedure SetEntryID(EntryID: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Email Entry ID");
        "Email Entry ID".CreateOutStream(OutStream);
        OutStream.WriteText(EntryID);
    end;

    procedure GetEmailMessageUrl() Return: Text
    var
        InStream: InStream;
    begin
        CalcFields("Email Message Url");
        "Email Message Url".CreateInStream(InStream);
        InStream.ReadText(Return);
    end;

    procedure SetEmailMessageUrl(Url: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Email Message Url");
        "Email Message Url".CreateOutStream(OutStream);
        OutStream.WriteText(url);
    end;

    procedure Read() Result: Text
    var
        DataInStream: InStream;
    begin
        Result := '';
        CalcFields("Attachment File");
        if not "Attachment File".HasValue() then
            exit;

        "Attachment File".CreateInStream(DataInStream, TEXTENCODING::UTF8);
        DataInStream.Read(Result);
    end;

    procedure Write(SourceText: Text)
    var
        DataOutStream: OutStream;
    begin
        "Attachment File".CreateOutStream(DataOutStream, TEXTENCODING::UTF8);
        DataOutStream.Write(SourceText);
    end;

    procedure ReadHTMLCustomLayoutAttachment(var ContentBodyText: Text; var CustomLayoutCode: Code[20]): Boolean
    var
        ReportLayoutName: Text[250];
    begin
        exit(ReadHTMLCustomLayoutAttachment(ContentBodyText, CustomLayoutCode, ReportLayoutName));
    end;

    procedure ReadHTMLCustomLayoutAttachment(var ContentBodyText: Text; var CustomLayoutCode: Code[20]; var ReportLayoutName: Text[250]): Boolean
    var
        DataText: Text;
    begin
        DataText := Read();
        if (DataText[1] = '<') and (StrPos(DataText, '>') > 1) then
            exit(ParseHTMLCustomLayoutAttachment(DataText, ContentBodyText, ReportLayoutName))
        else
            exit(ParseHTMLCustomLayoutAttachment(DataText, ContentBodyText, CustomLayoutCode));
    end;

    procedure WriteHTMLCustomLayoutAttachment(ContentBodyText: Text; CustomLayoutCode: Code[20])
    var
        DataText: Text;
    begin
        DataText := PadStr('', GetCustomLayoutCodeLength() - StrLen(CustomLayoutCode), '0') + CustomLayoutCode;
        DataText += ContentBodyText;
        Write(DataText);
        Modify();
    end;

    procedure WriteHTMLCustomLayoutAttachment(ContentBodyText: Text; ReportLayoutName: Text[250])
    begin
        Write('<' + ReportLayoutName + '>' + ContentBodyText);
        Modify();
    end;

    local procedure ParseHTMLCustomLayoutAttachment(DataText: Text; var ContentBodyText: Text; var CustomLayoutCode: Code[20]): Boolean
    var
        TotalLength: Integer;
        LayoutIDLength: Integer;
    begin
        LayoutIDLength := GetCustomLayoutCodeLength();
        TotalLength := StrLen(DataText);
        if TotalLength < LayoutIDLength then
            exit(false);

        if DataText = '' then
            exit;

        CustomLayoutCode := DelChr(CopyStr(DataText, 1, LayoutIDLength), '<', '0');
        if CustomLayoutCode = '' then
            exit;

        if TotalLength = LayoutIDLength then
            ContentBodyText := ''
        else
            ContentBodyText := CopyStr(DataText, LayoutIDLength + 1, TotalLength - LayoutIDLength);

        exit(true);
    end;

    local procedure ParseHTMLCustomLayoutAttachment(DataText: Text; var ContentBodyText: Text; var LayoutName: Text[250]): Boolean
    var
        i: Integer;
    begin

        if DataText = '' then
            exit(false);
        if DataText[1] <> '<' then
            exit(false);
        i := StrPos(DataText, '>');
        if i < 2 then
            exit(false);
        LayoutName := CopyStr(CopyStr(DataText, 2, i - 2), 1, MaxStrLen(LayoutName));
        if StrLen(DataText) < i + 1 then
            ContentBodyText := ''
        else
            ContentBodyText := CopyStr(DataText, i + 1);
        exit(true);
    end;

    procedure IsHTML(): Boolean
    begin
        exit(LowerCase("File Extension") = 'html');
    end;

    procedure IsHTMLReady(): Boolean
    var
        DataText: Text;
        DataLength: Integer;
        HTMLMask: Text;
        HTMLMaskLength: Integer;
    begin
        if not IsHTML() then
            exit(false);

        HTMLMask := '<html>';
        HTMLMaskLength := StrLen(HTMLMask);
        DataText := Read();
        DataLength := StrLen(DataText);

        if DataLength < HTMLMaskLength then
            exit(false);

        exit(LowerCase(CopyStr(DataText, 1, HTMLMaskLength)) = HTMLMask);
    end;

    procedure IsHTMLCustomLayout(): Boolean
    var
        DataText: Text;
        DataLength: Integer;
        CustomLayoutIDLength: Integer;
        CustomLayoutCode: Code[20];
    begin
        CustomLayoutIDLength := GetCustomLayoutCodeLength();
        if not IsHTML() then
            exit(false);

        DataText := Read();
        if DataText = '' then
            exit(false);
        DataLength := StrLen(DataText);

        // Is it a built-in layout name?
        if (DataLength > 6) and (DataText[1] = '<') and (DataText[DataLength] = '>') then
            exit(true);

        // Is it a custom layout code?
        if DataLength < CustomLayoutIDLength then
            exit(false);

        CustomLayoutCode := DelChr(DataText, '<', '0');
        exit(CustomLayoutCode <> '');
    end;

    local procedure GetCustomLayoutCodeLength(): Integer
    var
        DummyCustomReportLayout: Record "Custom Report Layout";
    begin
        exit(MaxStrLen(DummyCustomReportLayout.Code));
    end;

    local procedure ProcessWebAttachment(FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        if Confirm(AttachmentExportQst, true) then begin
            TempBlob.FromRecord(Rec, FieldNo("Attachment File"));
            FileManagement.BLOBExport(TempBlob, FileName, true);
            if not "Read Only" then
                if Confirm(AttachmentImportQst, true) then
                    ImportAttachmentFromClientFile('', IsTemporary, false);
        end
    end;

    procedure GetServerFileName(DiskFileName: Text): Text
    begin
        if not Exists(DiskFileName) then
            DiskFileName := DelChr(DiskFileName, '>', '.' + "File Extension");
        exit(DiskFileName);
    end;

    procedure SetAttachmentFileFromBlob(TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo("Attachment File"));
        RecordRef.SetTable(Rec);
    end;

    internal procedure SetAttachmentFileFromStream(InStream: InStream)
    var
        OutStream: OutStream;
    begin
        Rec."Attachment File".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyAttachmentAsFile(var FromAttachment: Record Attachment; var ToAttachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAttachment(var SegLine: Record "Segment Line"; WordCaption: Text; var IsHandled: Boolean; var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportAttachmentToServerFile(var Attachment: Record Attachment; ExportToFile: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImportAttachmentFromServerFile(var Attachment: Record Attachment; ImportFromFile: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowAttachmentOnAfterCalcAttachmentFile(var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenAttachment(var Attachment: Record Attachment; var Caption: Text[260]; IsTemporary: Boolean; LanguageCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWizSaveAttachment(var Attachment: Record Attachment; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWizEmbeddAttachment(var Attachment: Record Attachment; FromAttachment: Record Attachment; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConstDiskFileName(var Attachment: Record Attachment; var DiskFileName: Text)
    begin
    end;
}
