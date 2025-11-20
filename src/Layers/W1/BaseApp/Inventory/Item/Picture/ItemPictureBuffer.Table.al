// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Picture;

using Microsoft.Inventory.Item;
using System.IO;
using System.Utilities;

table 31 "Item Picture Buffer"
{
    Caption = 'Item Picture Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "File Name"; Text[260])
        {
            Caption = 'File Name';
        }
        field(2; Picture; Media)
        {
            Caption = 'Picture';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(4; "Item Description"; Text[100])
        {
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Caption = 'Item Description';
            FieldClass = FlowField;
        }
        field(5; "Import Status"; Option)
        {
            Caption = 'Import Status';
            Editable = false;
            OptionCaption = 'Skip,Pending,Completed';
            OptionMembers = Skip,Pending,Completed;
        }
        field(6; "Picture Already Exists"; Boolean)
        {
            Caption = 'Picture Already Exists';
        }
        field(7; "File Size (KB)"; BigInteger)
        {
            Caption = 'File Size (KB)';
        }
        field(8; "File Extension"; Text[30])
        {
            Caption = 'File Extension';
        }
        field(9; "Modified Date"; Date)
        {
            Caption = 'Modified Date';
        }
        field(10; "Modified Time"; Time)
        {
            Caption = 'Modified Time';
        }
    }

    keys
    {
        key(Key1; "File Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "File Name", "Item No.", "Item Description", Picture)
        {
        }
    }

    var
        SelectZIPFileMsg: Label 'Select ZIP File';

    [Scope('OnPrem')]
    procedure LoadZIPFile(ZipFileName: Text; var TotalCount: Integer; ReplaceMode: Boolean): Text
    var
        Item: Record Item;
        FileMgt: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        Window: Dialog;
        EntryList: List of [Text];
        EntryListKey: Text;
        ServerFile: File;
        InStream: InStream;
        EntryOutStream: OutStream;
        EntryInStream: InStream;
        ServerFileOpened: Boolean;
        Length: Integer;
    begin
        if ZipFileName <> '' then begin
            ServerFileOpened := ServerFile.Open(ZipFileName);
            ServerFile.CreateInStream(InStream)
        end else
            if not UploadIntoStream(SelectZIPFileMsg, '', 'Zip Files|*.zip', ZipFileName, InStream) then
                Error('');

        DataCompression.OpenZipArchive(InStream, false);
        DataCompression.GetEntryList(EntryList);

        Window.Open('#1##############################');

        TotalCount := 0;
        DeleteAll();
        foreach EntryListKey in EntryList do begin
            Init();
            "File Name" := CopyStr(FileMgt.GetFileNameWithoutExtension(EntryListKey), 1, MaxStrLen("File Name"));
            "File Extension" := CopyStr(FileMgt.GetExtension(EntryListKey), 1, MaxStrLen("File Extension"));
            if StrLen("File Name") <= MaxStrLen(Item."No.") then
                if Item.Get("File Name") then begin
                    TempBlob.CreateOutStream(EntryOutStream);
                    Length := DataCompression.ExtractEntry(EntryListKey, EntryOutStream);
                    TempBlob.CreateInStream(EntryInStream);
                    if not IsNullGuid(Picture.ImportStream(EntryInStream, FileMgt.GetFileName(EntryListKey))) then begin
                        Window.Update(1, "File Name");
                        "File Size (KB)" := Length;
                        TotalCount += 1;
                        "Item No." := Item."No.";
                        if Item.Picture.Count > 0 then begin
                            "Picture Already Exists" := true;
                            if ReplaceMode then
                                "Import Status" := "Import Status"::Pending;
                        end else
                            "Import Status" := "Import Status"::Pending;
                    end;
                    Insert();
                end;
        end;

        DataCompression.CloseZipArchive();
        Window.Close();

        if ServerFileOpened then
            ServerFile.Close();

        exit(ZipFileName);
    end;

    [Scope('OnPrem')]
    procedure ImportPictures(ReplaceMode: Boolean)
    var
        Item: Record Item;
        Window: Dialog;
        ImageID: Guid;
    begin
        Window.Open('#1############################################');

        if FindSet(true) then
            repeat
                if "Import Status" = "Import Status"::Pending then
                    if ("Item No." <> '') and ShouldImport(ReplaceMode, "Picture Already Exists") then begin
                        Window.Update(1, "Item No.");
                        Item.Get("Item No.");
                        ImageID := Picture.MediaId;
                        if "Picture Already Exists" then
                            Clear(Item.Picture);
                        Item.Picture.Insert(ImageID);
                        Item.Modify();
                        "Import Status" := "Import Status"::Completed;
                        Modify();
                    end;
            until Next() = 0;

        Window.Close();
    end;

    local procedure ShouldImport(ReplaceMode: Boolean; PictureExists: Boolean): Boolean
    begin
        if not ReplaceMode and PictureExists then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetAddCount(): Integer
    var
        TempItemPictureBuffer2: Record "Item Picture Buffer" temporary;
    begin
        TempItemPictureBuffer2.Copy(Rec, true);
        TempItemPictureBuffer2.SetRange("Import Status", TempItemPictureBuffer2."Import Status"::Pending);
        TempItemPictureBuffer2.SetRange("Picture Already Exists", false);
        exit(TempItemPictureBuffer2.Count);
    end;

    [Scope('OnPrem')]
    procedure GetAddedCount(): Integer
    var
        TempItemPictureBuffer2: Record "Item Picture Buffer" temporary;
    begin
        TempItemPictureBuffer2.Copy(Rec, true);
        TempItemPictureBuffer2.SetRange("Import Status", TempItemPictureBuffer2."Import Status"::Completed);
        TempItemPictureBuffer2.SetRange("Picture Already Exists", false);
        exit(TempItemPictureBuffer2.Count);
    end;

    [Scope('OnPrem')]
    procedure GetReplaceCount(): Integer
    var
        TempItemPictureBuffer2: Record "Item Picture Buffer" temporary;
    begin
        TempItemPictureBuffer2.Copy(Rec, true);
        TempItemPictureBuffer2.SetRange("Import Status", TempItemPictureBuffer2."Import Status"::Pending);
        TempItemPictureBuffer2.SetRange("Picture Already Exists", true);
        exit(TempItemPictureBuffer2.Count);
    end;

    [Scope('OnPrem')]
    procedure GetReplacedCount(): Integer
    var
        TempItemPictureBuffer2: Record "Item Picture Buffer" temporary;
    begin
        TempItemPictureBuffer2.Copy(Rec, true);
        TempItemPictureBuffer2.SetRange("Import Status", TempItemPictureBuffer2."Import Status"::Completed);
        TempItemPictureBuffer2.SetRange("Picture Already Exists", true);
        exit(TempItemPictureBuffer2.Count);
    end;
}

