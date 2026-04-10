// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

codeunit 9458 "File Account Browser Mgt."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        ExternalFileStorage: Codeunit "External File Storage";

    procedure SetFileAccount(TempFileAccount: Record "File Account" temporary)
    begin
        ExternalFileStorage.Initialize(TempFileAccount);
    end;

    procedure StripNotSupportedCharsInFileName(InText: Text): Text
    var
        InvalidCharsStringTxt: Label '"#%&*:<>?\/{|}~', Locked = true;
    begin
        InText := DelChr(InText, '=', InvalidCharsStringTxt);
        exit(InText);
    end;

    procedure BrowseFolder(var TempFileAccountContent: Record "File Account Content" temporary; Path: Text; var CurrentPath: Text; DoNotLoadFiles: Boolean; FileNameFilter: Text)
    var
        FilePaginationData: Codeunit "File Pagination Data";
    begin
        CurrentPath := Path.TrimEnd('/');
        TempFileAccountContent.DeleteAll();

        repeat
            ExternalFileStorage.ListDirectories(Path, FilePaginationData, TempFileAccountContent);
        until FilePaginationData.IsEndOfListing();

        ListFiles(TempFileAccountContent, Path, DoNotLoadFiles, FileNameFilter);
        AddParentFolder(TempFileAccountContent, CurrentPath);
        if TempFileAccountContent.FindFirst() then;
    end;

    procedure DownloadFile(var TempFileAccountContent: Record "File Account Content" temporary)
    var
        Stream: InStream;
        FileName: Text;
    begin
        ExternalFileStorage.GetFile(ExternalFileStorage.CombinePath(TempFileAccountContent."Parent Directory", TempFileAccountContent.Name), Stream);
        FileName := TempFileAccountContent.Name;
        DownloadFromStream(Stream, '', '', '', FileName);
    end;

    procedure UploadFile(Path: Text)
    var
        Stream: InStream;
        UploadDialogTxt: Label 'Upload File';
        FromFile: Text;
    begin
        if not UploadIntoStream(UploadDialogTxt, '', '', FromFile, Stream) then
            exit;

        ExternalFileStorage.CreateFile(ExternalFileStorage.CombinePath(Path, FromFile), Stream);
    end;

    procedure CreateDirectory(Path: Text)
    var
        FolderNameInput: Page "Folder Name Input";
        FolderName: Text;
    begin
        if FolderNameInput.RunModal() <> Action::OK then
            exit;

        FolderName := StripNotSupportedCharsInFileName(FolderNameInput.GetFolderName());
        ExternalFileStorage.CreateDirectory(ExternalFileStorage.CombinePath(Path, FolderName));
    end;

    local procedure ListFiles(var TempFileAccountContent: Record "File Account Content" temporary; Path: Text; DoNotLoadFields: Boolean; FileNameFilter: Text)
    var
        TempFileAccountContentToAdd: Record "File Account Content" temporary;
        FilePaginationData: Codeunit "File Pagination Data";
    begin
        if DoNotLoadFields then
            exit;

        repeat
            ExternalFileStorage.ListFiles(Path, FilePaginationData, TempFileAccountContentToAdd);
        until FilePaginationData.IsEndOfListing();

        AddFiles(TempFileAccountContent, TempFileAccountContentToAdd, FileNameFilter);
    end;

    local procedure AddFiles(var TempFileAccountContent: Record "File Account Content" temporary; var FileAccountContentToAdd: Record "File Account Content" temporary; FileNameFilter: Text)
    begin
        if FileNameFilter <> '' then
            FileAccountContentToAdd.SetFilter(Name, FileNameFilter);

        if FileAccountContentToAdd.FindSet() then
            repeat
                TempFileAccountContent.Init();
                TempFileAccountContent.TransferFields(FileAccountContentToAdd);
                TempFileAccountContent.Insert();
            until FileAccountContentToAdd.Next() = 0;
    end;

    local procedure AddParentFolder(var TempFileAccountContent: Record "File Account Content" temporary; CurrentPath: Text)
    var
        ParentFolder: Text;
    begin
        ParentFolder := ExternalFileStorage.GetParentPath(CurrentPath);
        if ParentFolder = CurrentPath then
            exit;

        TempFileAccountContent.Init();
        TempFileAccountContent.Validate(Name, '..');
        TempFileAccountContent.Validate(Type, TempFileAccountContent.Type::Directory);
        TempFileAccountContent.Validate("Parent Directory", CopyStr(ParentFolder, 1, MaxStrLen(TempFileAccountContent."Parent Directory")));
        TempFileAccountContent.Insert();
    end;

    procedure DeleteFileOrDirectory(var TempFileAccountContent: Record "File Account Content" temporary)
    var
        DeleteQst: Label 'Delete %1?', Comment = '%1 - Path to Delete';
        PathToDelete: Text;
    begin
        PathToDelete := ExternalFileStorage.CombinePath(TempFileAccountContent."Parent Directory", TempFileAccountContent.Name);
        if not Confirm(DeleteQst, false, PathToDelete) then
            exit;

        case TempFileAccountContent.Type of
            TempFileAccountContent.Type::Directory:
                ExternalFileStorage.DeleteDirectory(PathToDelete);
            TempFileAccountContent.Type::File:
                ExternalFileStorage.DeleteFile(PathToDelete);
        end;
    end;

    internal procedure CombinePath(Path: Text; ChildPath: Text): Text
    begin
        exit(ExternalFileStorage.CombinePath(Path, ChildPath));
    end;
}