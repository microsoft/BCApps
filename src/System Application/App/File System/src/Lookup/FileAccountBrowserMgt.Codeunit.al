codeunit 9458 "File Account Browser Mgt."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        FileSystem: Codeunit "File System";

    procedure SetFileAccount(FileAccount: Record "File Account")
    begin
        FileSystem.Initialize(FileAccount);
    end;

    procedure StripNotsupportChrInFileName(InText: Text): Text
    var
        InvalidChrStringTxt: Label '"#%&*:<>?\/{|}~', Locked = true;
    begin
        InText := DelChr(InText, '=', InvalidChrStringTxt);
        exit(InText);
    end;

    procedure BrowseFolder(var TempFileAccountContent: Record "File Account Content" temporary; Path: Text; var CurrPath: Text; DoNotLoadFiles: Boolean; FileNameFilter: Text)
    var
        FilePaginationData: Codeunit "File Pagination Data";
    begin
        CurrPath := Path.TrimEnd('/');
        TempFileAccountContent.DeleteAll();

        repeat
            FileSystem.ListDirectories(Path, FilePaginationData, TempFileAccountContent);
        until FilePaginationData.IsEndOfListing();

        ListFiles(TempFileAccountContent, Path, DoNotLoadFiles, CurrPath, FileNameFilter);
        if TempFileAccountContent.FindFirst() then;
    end;

    procedure DownloadFile(var TempFileAccountContent: Record "File Account Content" temporary)
    var
        Stream: InStream;
    begin
        FileSystem.GetFile(FileSystem.CombinePath(TempFileAccountContent."Parent Directory", TempFileAccountContent.Name), Stream);
        DownloadFromStream(Stream, '', '', '', TempFileAccountContent.Name);
    end;

    procedure UploadFile(Path: Text)
    var
        UploadDialogTxt: Label 'Upload File';
        FromFile: Text;
        Stream: InStream;
    begin
        if not UploadIntoStream(UploadDialogTxt, '', '', FromFile, Stream) then
            exit;

        FileSystem.CreateFile(FileSystem.CombinePath(Path, FromFile), Stream);
    end;

    procedure CreateDirectory(Path: Text)
    var
        FolderNameInput: Page "Folder Name Input";
        FolderName: Text;
    begin
        if FolderNameInput.RunModal() <> Action::OK then
            exit;

        FolderName := StripNotsupportChrInFileName(FolderNameInput.GetFolderName());
        FileSystem.CreateDirectory(FileSystem.CombinePath(Path, FolderName));
    end;

    local procedure ListFiles(var FileAccountContent: Record "File Account Content" temporary; var Path: Text; DoNotLoadFields: Boolean; CurrPath: Text; FileNameFilter: Text)
    var
        FileAccountContentToAdd: Record "File Account Content" temporary;
        FilePaginationData: Codeunit "File Pagination Data";
    begin
        if DoNotLoadFields then
            exit;

        repeat
            FileSystem.ListFiles(Path, FilePaginationData, FileAccountContent);
        until FilePaginationData.IsEndOfListing();

        AddFiles(FileAccountContent, FileAccountContentToAdd, CurrPath, FileNameFilter);
    end;

    local procedure AddFiles(var FileAccountContent: Record "File Account Content" temporary; var FileAccountContentToAdd: Record "File Account Content" temporary; CurrPath: Text; FileNameFilter: Text)
    begin
        if FileNameFilter <> '' then
            FileAccountContentToAdd.SetFilter(Name, FileNameFilter);

        if FileAccountContentToAdd.FindSet() then
            repeat
                FileAccountContent.Init();
                FileAccountContent.TransferFields(FileAccountContentToAdd);
                FileAccountContent.Insert();
            until FileAccountContentToAdd.Next() = 0;

        FileAccountContent.Init();
        FileAccountContent.Name := '..';
        FileAccountContent.Type := FileAccountContent.Type::Directory;
        FileAccountContent."Parent Directory" := FileSystem.GetParentPath(CurrPath);
        FileAccountContent.Insert();
    end;

    procedure DeleteFileOrDirectory(var TempFileAccountContent: Record "File Account Content" temporary)
    var
        PathToDelete: Text;
        DeleteQst: Label 'Delete %1?', Comment = '%1 - Path to Delete';
    begin
        PathToDelete := FileSystem.CombinePath(TempFileAccountContent."Parent Directory", TempFileAccountContent.Name);
        if not Confirm(DeleteQst, false, PathToDelete) then
            exit;

        case TempFileAccountContent.Type of
            TempFileAccountContent.Type::Directory:
                FileSystem.DeleteDirectory(PathToDelete);
            TempFileAccountContent.Type::File:
                FileSystem.DeleteFile(PathToDelete);
        end;
    end;

    internal procedure CombinePath(Path: Text; ChildPath: Text): Text
    begin
        exit(FileSystem.CombinePath(Path, ChildPath));
    end;
}