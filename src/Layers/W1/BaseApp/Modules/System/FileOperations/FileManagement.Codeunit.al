namespace System.IO;

using Microsoft.Utilities;
using System;
using System.Environment;
using System.Integration;
using System.Utilities;

codeunit 419 "File Management"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text001: Label 'Default';
#pragma warning restore AA0074
        FileDoesNotExistErr: Label 'The file %1 does not exist.', Comment = '%1 File Path';
#pragma warning disable AA0074
        Text006: Label 'Export';
        Text007: Label 'Import';
#pragma warning restore AA0074
        PathHelper: DotNet Path;
        [RunOnClient]
        DirectoryHelper: DotNet Directory;
        ServerFileHelper: DotNet File;
        ServerDirectoryHelper: DotNet Directory;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text013: Label 'The file name %1 already exists.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        AllFilesFilterTxt: Label '*.*', Locked = true;
        AllFilesDescriptionTxt: Label 'All Files (*.*)|*.*', Comment = '{Split=r''\|''}{Locked=s''1''}';
#pragma warning disable AA0074
        XMLFileType: Label 'XML Files (*.xml)|*.xml', Comment = '{Split=r''\|''}{Locked=s''1''}';
        WordFileType: Label 'Word Files (*.doc)|*.doc', Comment = '{Split=r''\|''}{Locked=s''1''}';
        Word2007FileType: Label 'Word Files (*.docx;*.doc)|*.docx;*.doc', Comment = '{Split=r''\|''}{Locked=s''1''}';
        ExcelFileType: Label 'Excel Files (*.xls)|*.xls', Comment = '{Split=r''\|''}{Locked=s''1''}';
        Excel2007FileType: Label 'Excel Files (*.xlsx;*.xls)|*.xlsx;*.xls', Comment = '{Split=r''\|''}{Locked=s''1''}';
        XSDFileType: Label 'XSD Files (*.xsd)|*.xsd', Comment = '{Split=r''\|''}{Locked=s''1''}';
        HTMFileType: Label 'HTM Files (*.htm)|*.htm', Comment = '{Split=r''\|''}{Locked=s''1''}';
        XSLTFileType: Label 'XSLT Files (*.xslt)|*.xslt', Comment = '{Split=r''\|''}{Locked=s''1''}';
        TXTFileType: Label 'Text Files (*.txt)|*.txt', Comment = '{Split=r''\|''}{Locked=s''1''}';
#pragma warning restore AA0074
        RDLFileTypeTok: Label 'SQL Report Builder (*.rdl;*.rdlc)|*.rdl;*.rdlc', Comment = '{Split=r''\|''}{Locked=s''1''}';
#pragma warning disable AA0470
        UnsupportedFileExtErr: Label 'Unsupported file extension (.%1). The supported file extensions are (%2).';
#pragma warning restore AA0470
        SingleFilterErr: Label 'Specify a file filter and an extension filter when using this function.';
        InvalidWindowsChrStringTxt: Label '"#%&*:<>?\/{|}~', Locked = true;
        DownloadImageTxt: Label 'Download image';
        NotAllowedPathErr: Label 'Files outside of the current user''s folder cannot be accessed. Access is denied to file %1.', Comment = '%1=the full path to a file. ex: C:\Windows\TextFile.txt ';
        AppendFileNameWithIndexTxt: Label '%1 (%2)', Locked = true, Comment = '%1 - original file name, %2 - append index';
        AppendFileNameWithExtWithIndexTxt: Label '%1 (%2).%3', Locked = true, Comment = '%1 - original file name, %2 - append index, %3 - extension';

    procedure BLOBImport(var TempBlob: Codeunit "Temp Blob"; Name: Text): Text
    begin
        exit(BLOBImportWithFilter(TempBlob, Text007, Name, AllFilesDescriptionTxt, AllFilesFilterTxt));
    end;

    procedure BLOBImportWithFilter(var TempBlob: Codeunit "Temp Blob"; DialogCaption: Text; Name: Text; FileFilter: Text; ExtFilter: Text): Text
    var
        NVInStream: InStream;
        NVOutStream: OutStream;
        UploadResult: Boolean;
        ErrorMessage: Text;
    begin
        // ExtFilter examples: 'csv,txt' if you only accept *.csv and *.txt or '*.*' if you accept any extensions
        ClearLastError();

        if (FileFilter = '') xor (ExtFilter = '') then
            Error(SingleFilterErr);

        // There is no way to check if NVInStream is null before using it after calling the
        // UPLOADINTOSTREAM therefore if result is false this is the only way we can throw the error.
        UploadResult := UploadIntoStream(DialogCaption, '', FileFilter, Name, NVInStream);
        if UploadResult then
            ValidateFileExtension(Name, ExtFilter);
        if UploadResult then begin
            TempBlob.CreateOutStream(NVOutStream);
            CopyStream(NVOutStream, NVInStream);
            exit(Name);
        end;
        ErrorMessage := GetLastErrorText;
        if ErrorMessage <> '' then
            Error(ErrorMessage);

        exit('');
    end;

    local procedure BLOBExportLocal(var InStream: InStream; Name: Text; IsCommonDialog: Boolean): Text
    var
        ToFile: Text;
        Path: Text;
        IsDownloaded: Boolean;
    begin
        if IsCommonDialog then begin
            if StrPos(Name, '*') = 0 then
                ToFile := Name
            else
                ToFile := DelChr(InsStr(Name, Text001, 1), '=', '*');
            Path := PathHelper.GetDirectoryName(ToFile);
            ToFile := GetFileName(ToFile);
        end else begin
            ToFile := CreateFileNameWithExtension(Format(CreateGuid()), GetExtension(Name));
            Path := Magicpath();
        end;
        IsDownloaded := DownloadFromStream(InStream, Text006, Path, GetToFilterText('', Name), ToFile);
        if IsDownloaded then
            exit(ToFile);
        exit('');
    end;

    procedure BLOBExportWithEncoding(var TempBlob: Codeunit "Temp Blob"; Name: Text; CommonDialog: Boolean; Encoding: TextEncoding) Result: Text
    var
        NVInStream: InStream;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBlobExportWithEncoding(TempBlob, Name, CommonDialog, Encoding, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempBlob.CreateInStream(NVInStream, Encoding);
        exit(BLOBExportLocal(NVInStream, Name, CommonDialog));
    end;

    procedure BLOBExport(var TempBlob: Codeunit "Temp Blob"; Name: Text; CommonDialog: Boolean) Result: Text
    var
        NVInStream: InStream;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBlobExport(TempBlob, Name, CommonDialog, IsHandled, Result);
        if IsHandled then
            exit(Result);

        TempBlob.CreateInStream(NVInStream);
        exit(BLOBExportLocal(NVInStream, Name, CommonDialog));
    end;

    [Scope('OnPrem')]
    procedure ServerTempFileName(FileExtension: Text) FileName: Text
    var
        TempFile: File;
    begin
        TempFile.CreateTempFile();
        FileName := CreateFileNameWithExtension(TempFile.Name, FileExtension);
        TempFile.Close();
    end;

#pragma warning disable AS0022
    [Scope('OnPrem')]
    procedure DownloadTempFile(ServerFileName: Text): Text
    var
        FileName: Text;
        Path: Text;
    begin
        FileName := ServerFileName;
        Path := Magicpath();
        Download(ServerFileName, '', Path, AllFilesDescriptionTxt, FileName);
        exit(FileName);
    end;
#pragma warning restore AS0022

    [Scope('OnPrem')]
    procedure UploadFile(WindowTitle: Text[50]; ClientFileName: Text) ServerFileName: Text
    var
        "Filter": Text;
    begin
        Filter := GetToFilterText('', ClientFileName);

        if PathHelper.GetFileNameWithoutExtension(ClientFileName) = '' then
            ClientFileName := '';

        ServerFileName := UploadFileWithFilter(WindowTitle, ClientFileName, Filter, AllFilesFilterTxt);
    end;

    [Scope('OnPrem')]
    procedure UploadFileWithFilter(WindowTitle: Text[50]; ClientFileName: Text; FileFilter: Text; ExtFilter: Text) ServerFileName: Text
    var
        Uploaded: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUploadFileWithFilter(ServerFileName, WindowTitle, ClientFileName, FileFilter, ExtFilter, IsHandled);
        if IsHandled then
            exit;

        ClearLastError();

        if (FileFilter = '') xor (ExtFilter = '') then
            Error(SingleFilterErr);

        Uploaded := Upload(WindowTitle, '', FileFilter, ClientFileName, ServerFileName);
        if Uploaded then
            ValidateFileExtension(ClientFileName, ExtFilter);
        if Uploaded then
            exit(ServerFileName);

        if GetLastErrorText <> '' then
            Error('%1', GetLastErrorText);

        exit('');
    end;

    procedure Magicpath(): Text
    begin
        exit('<TEMP>');   // MAGIC PATH makes sure we don't get a prompt
    end;

    [Scope('OnPrem')]
    procedure DownloadHandler(FromFile: Text; DialogTitle: Text; ToFolder: Text; ToFilter: Text; ToFile: Text) Downloaded: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDownloadHandler(ToFolder, ToFile, FromFile, IsHandled, Downloaded);
        if not IsHandled then begin
            ClearLastError();
            Downloaded := Download(FromFile, DialogTitle, ToFolder, ToFilter, ToFile);
            if not Downloaded then
                if GetLastErrorText <> '' then
                    Error('%1', GetLastErrorText);
        end;
        OnAfterDownloadHandler(ToFolder, ToFile, FromFile, Downloaded);
    end;

    procedure DownloadFromStreamHandler(FromInStream: InStream; DialogTitle: Text; ToFolder: Text; ToFilter: Text; ToFile: Text): Boolean
    var
        Downloaded: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDownloadFromStreamHandler(ToFolder, ToFile, FromInStream, IsHandled);
        if IsHandled then
            exit(true);

        ClearLastError();
        Downloaded := DownloadFromStream(FromInStream, DialogTitle, ToFolder, ToFilter, ToFile);
        if not Downloaded then
            if GetLastErrorText <> '' then
                Error('%1', GetLastErrorText);
        exit(Downloaded);
    end;

    [Scope('OnPrem')]
    procedure CopyServerFile(SourceFileName: Text; TargetFileName: Text; Overwrite: Boolean)
    begin
        IsAllowedPath(SourceFileName, false);
        IsAllowedPath(TargetFileName, false);
        ServerFileHelper.Copy(SourceFileName, TargetFileName, Overwrite);
    end;

    procedure ServerFileExists(FilePath: Text): Boolean
    begin
        exit(Exists(FilePath));
    end;

    [Scope('OnPrem')]
    procedure DeleteServerFile(FilePath: Text): Boolean
    begin
        IsAllowedPath(FilePath, false);
        if not Exists(FilePath) then
            exit(false);

        ServerFileHelper.Delete(FilePath);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ServerDirectoryExists(DirectoryPath: Text): Boolean
    begin
        IsAllowedPath(DirectoryPath, false);
        exit(ServerDirectoryHelper.Exists(DirectoryPath));
    end;

    [Scope('OnPrem')]
    procedure ServerCreateDirectory(DirectoryPath: Text)
    begin
        IsAllowedPath(DirectoryPath, false);
        if not ServerDirectoryExists(DirectoryPath) then
            ServerDirectoryHelper.CreateDirectory(DirectoryPath);
    end;

    [Scope('OnPrem')]
    procedure ServerCreateTempSubDirectory() DirectoryPath: Text
    var
        ServerTempFile: Text;
    begin
        ServerTempFile := ServerTempFileName('tmp');
        DirectoryPath := CombinePath(GetDirectoryName(ServerTempFile), Format(CreateGuid()));
        ServerCreateDirectory(DirectoryPath);
        DeleteServerFile(ServerTempFile);
    end;

    [Scope('OnPrem')]
    procedure ServerRemoveDirectory(DirectoryPath: Text; Recursive: Boolean)
    begin
        IsAllowedPath(DirectoryPath, false);
        if ServerDirectoryExists(DirectoryPath) then
            ServerDirectoryHelper.Delete(DirectoryPath, Recursive);
    end;

    procedure GetFileName(FilePath: Text): Text
    begin
        exit(PathHelper.GetFileName(FilePath));
    end;

    procedure GetSafeFileName(FileName: Text): Text
    var
        DotNetString: DotNet String;
        Result: Text;
        Str: Text;
    begin
        DotNetString := FileName;
        foreach Str in DotNetString.Split(PathHelper.GetInvalidFileNameChars()) do
            Result += Str;
        exit(Result);
    end;

    procedure GetPathWithSafeFileName(InFilePath: Text): Text
    var
        FileDirectory: Text;
        FileName: Text;
    begin
        FileDirectory := GetDirectoryName(InFilePath);
        FileName := GetSafeFileName(GetFileName(InFilePath));
        exit(CombinePath(FileDirectory, FileName));
    end;

    procedure GetFileNameWithoutExtension(FilePath: Text): Text
    begin
        exit(PathHelper.GetFileNameWithoutExtension(FilePath));
    end;

    procedure HasExtension(FilePath: Text): Boolean
    begin
        exit(PathHelper.HasExtension(FilePath));
    end;

    procedure GetFileNameMimeType(FileName: Text): Text
    var
        FileExtensionContentTypeProvider: DotNet FileExtensionContentTypeProvider;
        ContentType: Text;
    begin
        FileExtensionContentTypeProvider := FileExtensionContentTypeProvider.FileExtensionContentTypeProvider();
        FileExtensionContentTypeProvider.TryGetContentType(FileName, ContentType);
        exit(ContentType);
    end;

    procedure GetDirectoryName(FileName: Text): Text
    begin
        if FileName = '' then
            exit(FileName);

        FileName := DelChr(FileName, '<');
        exit(PathHelper.GetDirectoryName(FileName));
    end;

    [Scope('OnPrem')]
    procedure GetServerDirectoryFilesList(var NameValueBuffer: Record "Name/Value Buffer"; DirectoryPath: Text)
    var
        ArrayHelper: DotNet Array;
        i: Integer;
    begin
        NameValueBuffer.Reset();
        NameValueBuffer.DeleteAll();

        IsAllowedPath(DirectoryPath, false);
        ArrayHelper := ServerDirectoryHelper.GetFiles(DirectoryPath);
        for i := 1 to ArrayHelper.GetLength(0) do begin
            NameValueBuffer.ID := i;
            Evaluate(NameValueBuffer.Name, ArrayHelper.GetValue(i - 1));
            NameValueBuffer.Value := CopyStr(GetFileNameWithoutExtension(NameValueBuffer.Name), 1, 250);
            NameValueBuffer.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetServerDirectoryFilesListInclSubDirs(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; DirectoryPath: Text)
    begin
        TempNameValueBuffer.Reset();
        TempNameValueBuffer.DeleteAll();

        GetServerDirectoryFilesListInclSubDirsInner(TempNameValueBuffer, DirectoryPath);
    end;

    local procedure GetServerDirectoryFilesListInclSubDirsInner(var NameValueBuffer: Record "Name/Value Buffer"; DirectoryPath: Text)
    var
        ArrayHelper: DotNet Array;
        FileSystemEntry: Text;
        Index: Integer;
        LastId: Integer;
    begin
        IsAllowedPath(DirectoryPath, false);
        ArrayHelper := ServerDirectoryHelper.GetFileSystemEntries(DirectoryPath);
        for Index := 1 to ArrayHelper.GetLength(0) do begin
            if NameValueBuffer.FindLast() then
                LastId := NameValueBuffer.ID;
            Evaluate(FileSystemEntry, ArrayHelper.GetValue(Index - 1));
            if ServerDirectoryExists(FileSystemEntry) then
                GetServerDirectoryFilesListInclSubDirsInner(NameValueBuffer, FileSystemEntry)
            else begin
                NameValueBuffer.ID := LastId + 1;
                NameValueBuffer.Name := CopyStr(FileSystemEntry, 1, 250);
                NameValueBuffer.Value := CopyStr(GetFileNameWithoutExtension(NameValueBuffer.Name), 1, 250);
                NameValueBuffer.Insert();
            end;
        end;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure GetServerFileProperties(FullFileName: Text; var ModifyDate: Date; var ModifyTime: Time; var Size: BigInteger)
    var
        FileInfo: DotNet FileInfo;
        ModifyDateTime: DateTime;
    begin
        IsAllowedPath(FullFileName, false);
        ModifyDateTime := ServerDirectoryHelper.GetLastWriteTime(FullFileName);
        ModifyDate := DT2Date(ModifyDateTime);
        ModifyTime := DT2Time(ModifyDateTime);
        Size := FileInfo.FileInfo(FullFileName).Length;
    end;

    procedure CombinePath(BasePath: Text; Suffix: Text): Text
    begin
        exit(PathHelper.Combine(BasePath, Suffix));
    end;

    [Scope('OnPrem')]
    procedure BLOBImportFromServerFile(var TempBlob: Codeunit "Temp Blob"; FilePath: Text)
    var
        OutStream: OutStream;
        InStream: InStream;
        InputFile: File;
    begin
        IsAllowedPath(FilePath, false);

        if not FILE.Exists(FilePath) then
            Error(FileDoesNotExistErr, FilePath);

        InputFile.Open(FilePath);
        InputFile.CreateInStream(InStream);
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        InputFile.Close();
    end;

    [Scope('OnPrem')]
    procedure BLOBExportToServerFile(var TempBlob: Codeunit "Temp Blob"; FilePath: Text)
    var
        OutStream: OutStream;
        InStream: InStream;
        OutputFile: File;
    begin
        if FILE.Exists(FilePath) then
            Error(Text013, FilePath);

        OutputFile.WriteMode(true);
        OutputFile.Create(FilePath);
        OutputFile.CreateOutStream(OutStream);
        TempBlob.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        OutputFile.Close();
    end;

    [Scope('OnPrem')]
    procedure InstreamExportToServerFile(Instream: InStream; FileExt: Text) FileName: Text
    var
        OutStream: OutStream;
        OutputFile: File;
    begin
        FileName := CopyStr(ServerTempFileName(FileExt), 1, 250);
        OutputFile.WriteMode(true);
        OutputFile.Create(FileName);
        OutputFile.CreateOutStream(OutStream);
        CopyStream(OutStream, Instream);
        OutputFile.Close();
    end;

    [Scope('OnPrem')]
    internal procedure TempBlobToServerFile(var TempBlob: Codeunit "Temp Blob"; FileExt: Text) TempServerFilePath: Text[250]
    var
        FileInstream: InStream;
    begin
        TempBlob.CreateInStream(FileInstream, TextEncoding::UTF8);
        TempServerFilePath := CopyStr(InstreamExportToServerFile(FileInstream, FileExt), 1, MaxStrLen(TempServerFilePath));
    end;

    [Scope('OnPrem')]
    procedure CreateAndWriteToServerFile(FileContent: Text; FileExt: Text) FileName: Text
    var
        File: File;
        OutStream: OutStream;
    begin
        FileName := CopyStr(ServerTempFileName(FileExt), 1, 250);
        File.Create(FileName);
        File.CreateOutStream(OutStream);
        OutStream.WriteText(FileContent);
        File.Close();
    end;

    procedure GetToFilterText(FilterString: Text; FileName: Text): Text
    var
        OutExt: Text;
    begin
        if FilterString <> '' then
            exit(FilterString);

        case UpperCase(GetExtension(FileName)) of
            'DOC':
                OutExt := WordFileType;
            'DOCX':
                OutExt := Word2007FileType;
            'XLS':
                OutExt := ExcelFileType;
            'XLSX':
                OutExt := Excel2007FileType;
            'XSLT':
                OutExt := XSLTFileType;
            'XML':
                OutExt := XMLFileType;
            'XSD':
                OutExt := XSDFileType;
            'HTM':
                OutExt := HTMFileType;
            'TXT':
                OutExt := TXTFileType;
            'RDL':
                OutExt := RDLFileTypeTok;
            'RDLC':
                OutExt := RDLFileTypeTok;
        end;

        OnAfterGetToFilterTextSetOutExt(FileName, OutExt);

        if OutExt = '' then
            exit(AllFilesDescriptionTxt);
        exit(OutExt + '|' + AllFilesDescriptionTxt);  // Also give the option of the general selection
    end;

    procedure GetExtension(Name: Text): Text
    var
        FileExtension: Text;
    begin
        FileExtension := PathHelper.GetExtension(Name);

        if FileExtension <> '' then
            FileExtension := DelChr(FileExtension, '<', '.');

        exit(FileExtension);
    end;

    procedure IsValidFileName(FileName: Text): Boolean
    var
        String: DotNet String;
    begin
        if FileName = '' then
            exit(false);

        String := GetFileName(FileName);
        if String.IndexOfAny(PathHelper.GetInvalidFileNameChars()) <> -1 then
            exit(false);

        String := GetDirectoryName(FileName);
        if String.IndexOfAny(PathHelper.GetInvalidPathChars()) <> -1 then
            exit(false);

        exit(true);
    end;

    procedure ValidateFileExtension(FilePath: Text; ValidExtensions: Text)
    var
        FileExt: Text;
        LowerValidExts: Text;
    begin
        if StrPos(ValidExtensions, AllFilesFilterTxt) <> 0 then
            exit;

        FileExt := LowerCase(GetExtension(GetFileName(FilePath)));
        LowerValidExts := LowerCase(ValidExtensions);

        if StrPos(LowerValidExts, FileExt) = 0 then
            Error(UnsupportedFileExtErr, FileExt, LowerValidExts);
    end;

    procedure CreateFileNameWithExtension(FileNameWithoutExtension: Text; Extension: Text) FileName: Text
    begin
        FileName := FileNameWithoutExtension;
        if Extension <> '' then begin
            if Extension[1] <> '.' then
                FileName := FileName + '.';
            FileName := FileName + Extension;
        end
    end;

    procedure Ansi2SystemEncoding(Destination: OutStream; Source: InStream)
    var
        StreamReader: DotNet StreamReader;
        Encoding: DotNet Encoding;
        EncodedTxt: Text;
    begin
        StreamReader := StreamReader.StreamReader(Source, Encoding.GetEncoding(0), true);
        EncodedTxt := StreamReader.ReadToEnd();
        Destination.WriteText(EncodedTxt);
    end;

    procedure Ansi2SystemEncodingTxt(Destination: OutStream; Source: Text)
    var
        StreamWriter: DotNet StreamWriter;
        Encoding: DotNet Encoding;
    begin
        StreamWriter := StreamWriter.StreamWriter(Destination, Encoding.GetEncoding(0));
        StreamWriter.Write(Source);
        StreamWriter.Close();
    end;

    procedure StripNotsupportChrInFileName(InText: Text): Text
    begin
        InText := DelChr(InText, '=', InvalidWindowsChrStringTxt);
        exit(GetSafeFileName(InText));
    end;

    [Scope('OnPrem')]
    procedure ExportImage(ImagetPath: Text; ToFile: Text)
    var
        NameValueBuffer: Record "Name/Value Buffer";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileManagement: Codeunit "File Management";
    begin
        NameValueBuffer.DeleteAll();
        FileManagement.GetServerDirectoryFilesList(TempNameValueBuffer, TemporaryPath);
        TempNameValueBuffer.SetFilter(Name, StrSubstNo('%1*', ImagetPath));
        TempNameValueBuffer.FindFirst();
        ToFile := StripNotsupportChrInFileName(ToFile);
        Download(TempNameValueBuffer.Name, DownloadImageTxt, '', '', ToFile);
        if FileManagement.DeleteServerFile(TempNameValueBuffer.Name) then;
    end;

    [Scope('OnPrem')]
    procedure IsClientDirectoryEmpty(Path: Text): Boolean
    begin
        if DirectoryHelper.Exists(Path) then
            exit(DirectoryHelper.GetFiles(Path).Length = 0);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsServerDirectoryEmpty(Path: Text): Boolean
    begin
        IsAllowedPath(Path, false);
        if ServerDirectoryHelper.Exists(Path) then
            exit(ServerDirectoryHelper.GetFiles(Path).Length = 0);
        exit(false);
    end;

    /// <summary>
    /// Gets the file contents as text from the file path provided in UTF8 text encoding.
    /// </summary>
    /// <param name="FilePath">The path to the file.</param>
    /// <returns>The text content of the file in UTF8 text encoding.</returns>
    [Scope('OnPrem')]
    procedure GetFileContents(FilePath: Text) Result: Text
    begin
        exit(GetFileContents(FilePath, TextEncoding::UTF8));
    end;

    /// <summary>
    /// Gets the file contents as text from the file path provided in the requested text encoding.
    /// </summary>
    /// <param name="FilePath">The path to the file.</param>
    /// <param name="Encoding">The text encoding to open the file with.</param>
    /// <returns>The text content of the file in requested text encoding.</returns>
    [Scope('OnPrem')]
    procedure GetFileContents(FilePath: Text; Encoding: TextEncoding) Result: Text
    var
        FileHandle: File;
        InStr: InStream;
    begin
        if not FILE.Exists(FilePath) then
            exit;

        FileHandle.Open(FilePath, Encoding);
        FileHandle.CreateInStream(InStr);

        InStr.Read(Result);
    end;

    procedure IsAllowedPath(Path: Text; SkipError: Boolean): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        WebRequestHelper: Codeunit "Web Request Helper";
    begin
        if EnvironmentInformation.IsSaaS() then
            if not WebRequestHelper.IsHttpUrl(Path) then begin
                ClearLastError();
                if not FILE.IsPathTemporary(Path) then begin
                    if SkipError then
                        exit(false);
                    Error(NotAllowedPathErr, Path);
                end;
            end;
        exit(true)
    end;

    procedure AppendFileNameWithIndex(OriginalFileName: Text; AppendIndex: Integer): Text
    var
        Extension: Text;
        FileNameWithoutExtension: Text;
    begin
        // convert "file.txt" to "file (1).txt"
        Extension := GetExtension(OriginalFileName);
        if Extension = '' then
            exit(StrSubstNo(AppendFileNameWithIndexTxt, OriginalFileName, Format(AppendIndex)));

        FileNameWithoutExtension := CopyStr(OriginalFileName, 1, StrLen(OriginalFileName) - StrLen(Extension) - 1);
        exit(StrSubstNo(AppendFileNameWithExtWithIndexTxt, FileNameWithoutExtension, Format(AppendIndex), Extension));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetToFilterTextSetOutExt(FileName: Text; var OutExt: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var Downloaded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlobExport(var TempBlob: Codeunit "Temp Blob"; Name: Text; CommonDialog: Boolean; var IsHandled: Boolean; var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlobExportWithEncoding(var TempBlob: Codeunit "Temp Blob"; Name: Text; CommonDialog: Boolean; Encoding: TextEncoding; var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean; var Downloaded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUploadFileWithFilter(var ServerFileName: Text; WindowTitle: Text[50]; ClientFileName: Text; FileFilter: Text; ExtFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadFromStreamHandler(var ToFolder: Text; ToFileName: Text; FromInStream: InStream; var IsHandled: Boolean)
    begin
    end;
}

