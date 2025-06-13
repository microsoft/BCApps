namespace System.SFTPClient;

using System.Azure.Storage;
using System.SFTPClient;
using System.IO;
using System.Security.AccessControl;
using System.Utilities;

page 50100 "SFTP Client - Debug"
{
    Caption = 'SFTP Client - Debug';
    PageType = Card;
    ApplicationArea = None;
    UsageCategory = None;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            group(Connection)
            {
                Caption = 'Connection';
                field(HostName; HostName)
                {
                    ApplicationArea = All;
                    Caption = 'Host Name';
                    ToolTip = 'The hostname or IP address of the SFTP server.';
                }
                field(Port; Port)
                {
                    ApplicationArea = All;
                    Caption = 'Port';
                    ToolTip = 'The port number of the SFTP server.';
                }
                field(UserName; UserName)
                {
                    ApplicationArea = All;
                    Caption = 'User Name';
                    ToolTip = 'The username for authentication on the SFTP server.';
                }
                field(Password; Password)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                    Caption = 'Password';
                    ToolTip = 'The password for authentication on the SFTP server.';
                    ShowMandatory = true;
                }
                field(WorkingDirectory; WorkingDirectory)
                {
                    ApplicationArea = All;
                    Caption = 'Working Directory';
                    ToolTip = 'The working directory on the SFTP server.';
                    Editable = false;
                }
            }
            group(FileTransfer)
            {
                Caption = 'File Transfer';
                field(NewDirectory; NewDirectory)
                {
                    ApplicationArea = All;
                    Caption = 'New Directory';
                    ToolTip = 'The new directory to change to on the SFTP server.';
                }
                field(SourceFile; SourceFile)
                {
                    ApplicationArea = All;
                    Caption = 'Source File';
                    ToolTip = 'The path of the original file on the SFTP server.';
                }
                field(DestinationFile; DestinationFile)
                {
                    ApplicationArea = All;
                    Caption = 'Destination File';
                    ToolTip = 'The path of the destination file on the SFTP server.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InitializeUsernamePassword)
            {
                ApplicationArea = All;
                Image = User;
                Caption = 'Connect with Username and Password';
                ToolTip = 'Initializes the SFTP client using the Host Name, Port, User Name, and Password fields.';

                trigger OnAction()
                begin
                    TestSftpClientPassword();
                end;
            }
            action(InitializePrivateKeyNoPassphrase)
            {
                ApplicationArea = All;
                Image = Certificate;
                Caption = 'Connect SFTP Client with Private Key (No Passphrase)';
                ToolTip = 'Initializes the SFTP client using the Host Name, Port, User Name fields and a private key file you select.';

                trigger OnAction()
                begin
                    TestSftpClientPrivateKey();
                end;
            }
            action(InitializePrivateKeysPassphrase)
            {
                ApplicationArea = All;
                Image = UserCertificate;
                Caption = 'Connect SFTP Client with Private Key (With Passphrase)';
                ToolTip = 'Initializes the SFTP client using the Host Name, Port, User Name fields, a private key file you select, and a passphrase.';

                trigger OnAction()
                begin
                    TestSftpClientPrivateKeyPasspharse();
                end;
            }
            action(UploadFile)
            {
                Image = Import;
                ApplicationArea = All;
                Caption = 'Upload File';
                ToolTip = 'Uploads a file to the SFTP server. Uses the Source File field to select a local file and the Destination File field for the target path on the server.';

                trigger OnAction()
                var
                    FileManagement: Codeunit "File Management";
                    TempBlob: Codeunit "Temp Blob";
                    Instream: InStream;
                begin
                    FileManagement.BLOBImport(TempBlob, SourceFile);
                    Instream := TempBlob.CreateInStream();
                    ShowException(SFTPClient.PutFileStream(DestinationFile, Instream));
                end;
            }
            action(DownloadFile)
            {
                Caption = 'Download File';
                ToolTip = 'Downloads a file from the SFTP server. Uses the Source File field for the file path on the server and the Destination File field for the local target path.';
                Image = Export;
                ApplicationArea = All;

                trigger OnAction()
                var
                    Filemanagement: Codeunit "File Management";
                    TempBlob: Codeunit "Temp Blob";
                    ABSBlobClient: Codeunit "ABS Blob Client";
                    InStream: InStream;
                begin
                    ShowException(SFTPClient.GetFileAsStream(SourceFile, InStream));
                    CopyStream(TempBlob.CreateOutStream(), InStream);
                    Filemanagement.BLOBExport(TempBlob, DestinationFile, true);
                end;
            }
            action(DeleteFile)
            {
                Caption = 'Delete File';
                ToolTip = 'Deletes a file from the SFTP server. Uses the Source File field for the file path to delete.';
                Image = Delete;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ShowException(SFTPClient.DeleteFile(SourceFile));
                end;
            }
            action(ListFiles)
            {
                Caption = 'List Files';
                ToolTip = 'Lists files in a directory on the SFTP server. Uses the New Directory field for the directory path to list.';
                Image = ShowList;
                ApplicationArea = All;

                trigger OnAction()
                var
                    SFTPFolderContent: Record "SFTP Folder Content";
                begin
                    ShowException(SFTPClient.ListFiles(NewDirectory, SFTPFolderContent));
                    Page.Run(Page::"SFTP Folder Content", SFTPFolderContent);
                end;
            }
            action(ListFilesInterfaces)
            {
                Caption = 'List Files (Interfaces)';
                ToolTip = 'Lists files in a directory on the SFTP server using interfaces. Uses the New Directory field for the directory path to list.';
                Image = CheckList;
                ApplicationArea = All;

                trigger OnAction()
                var
                    ISFTPFileList: List of [Interface "ISFTP File"];
                    ISFTPFile: Interface "ISFTP File";
                    TextBuilder: TextBuilder;
                    FileExistsLbl: Label 'Files in %1:';
                    FilePlaceHolderLbl: Label '%1 (%2)';
                begin
                    ShowException(SFTPClient.ListFiles(NewDirectory, ISFTPFileList));
                    TextBuilder.AppendLine(StrSubstNo(FileExistsLbl, NewDirectory));
                    foreach ISftpFile in ISFTPFileList do begin
                        TextBuilder.AppendLine(StrSubstNo(FilePlaceHolderLbl, ISftpFile.Name(), ISftpFile.FullName()));
                    end;
                    Message(TextBuilder.ToText());
                end;
            }
            action(FileExists)
            {
                Caption = 'File Exists';
                ToolTip = 'Checks if a file exists on the SFTP server. Uses the Source File field for the file path to check.';
                Image = TestFile;
                ApplicationArea = All;

                trigger OnAction()
                var
                    IsFileExists: Boolean;
                    FileExistsLbl: Label 'File %1 exists: %2';
                begin
                    ShowException(SFTPClient.FileExists(SourceFile, IsFileExists));
                    Message(FileExistsLbl, SourceFile, IsFileExists);
                end;
            }
            action(MoveFile)
            {
                Caption = 'Move File';
                ToolTip = 'Moves a file from one path to another on the SFTP server. Uses the Source File field for the original path and the Destination File field for the target path.';
                Image = TransferOrder;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ShowException(SFTPClient.MoveFile(SourceFile, DestinationFile));
                end;
            }
            action(IsConnected)
            {
                Caption = 'Is Connected';
                ToolTip = 'Checks if the SFTP client is currently connected to the server. Does not use any input fields.';
                Image = LinkWeb;
                ApplicationArea = All;

                trigger OnAction()
                var
                    IsConnectedLbl: Label 'Is connected: %1';
                begin
                    Message(IsConnectedLbl, SFTPClient.IsConnected());
                end;
            }
            action(ChangeDirectory)
            {
                Caption = 'Change Directory';
                ToolTip = 'Changes the working directory on the SFTP server. Uses the New Directory field for the target directory path.';
                Image = Navigate;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ShowException(SFTPClient.SetWorkingDirectory(NewDirectory));
                    ShowException(SFTPClient.GetWorkingDirectory(WorkingDirectory));
                end;
            }
            action(ShowWorkingDirectory)
            {
                Caption = 'Show Working Directory';
                ToolTip = 'Shows the current working directory on the SFTP server. Updates the Working Directory field with the result.';
                Image = OpenWorksheet;
                ApplicationArea = All;

                trigger OnAction()
                var
                    CurrentWorkingDirectoryLbl: Label 'Current working directory: %1';
                begin
                    ShowException(SFTPClient.GetWorkingDirectory(WorkingDirectory));
                    Message(CurrentWorkingDirectoryLbl, WorkingDirectory);
                end;
            }
            action(CreateDirectory)
            {
                Caption = 'Create Directory';
                ToolTip = 'Creates a new directory on the SFTP server. Uses the New Directory field for the path of the new directory.';
                Image = NewItem;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ShowException(SFTPClient.CreateDirectory(NewDirectory));
                end;
            }
            action(Disconnect)
            {
                Caption = 'Disconnect';
                ToolTip = 'Disconnects from the SFTP server. Clears the Working Directory field after disconnection.';
                Image = DeleteXML;
                ApplicationArea = All;

                trigger OnAction()
                var
                    DisconnectedLbl: Label 'Disconnected from SFTP server.';
                begin
                    SFTPClient.Disconnect();
                    Message(DisconnectedLbl);
                    WorkingDirectory := '';
                end;
            }
        }
        area(Promoted)
        {
            group(Connect)
            {
                Caption = 'Connect';
                ShowAs = SplitButton;
                actionref(InitializeUsernamePassword_Promoted; InitializeUsernamePassword) { }
                actionref(InitializePrivateKeyNoPassphrase_Promoted; InitializePrivateKeyNoPassphrase) { }
                actionref(InitializePrivateKeysPassphrase_Promoted; InitializePrivateKeysPassphrase) { }
                actionref(IsConnected_Promoted; IsConnected) { }
                actionref(ShowWorkingDirectory_Promoted; ShowWorkingDirectory) { }
            }
            group(DirectoryOperations)
            {
                Caption = 'Directory Operations';
                ShowAs = SplitButton;
                actionref(ChangeDirectory_Promoted; ChangeDirectory) { }
                actionref(ListFiles_Promoted; ListFiles) { }
                actionref(ListFilesInterfaces_Promoted; ListFilesInterfaces) { }
                actionref(CreateDirectory_Promoted; CreateDirectory) { }
            }
            group(FileOperations)
            {
                Caption = 'File Operations';
                ShowAs = SplitButton;
                actionref(FileExists_Promoted; FileExists) { }
                actionref(UploadFile_Promoted; UploadFile) { }
                actionref(DownloadFile_Promoted; DownloadFile) { }
                actionref(MoveFile_Promoted; MoveFile) { }
                actionref(DeleteFile_Promoted; DeleteFile) { }
            }
            group(DisconnectGroup)
            {
                Caption = 'Disconnect';
                ShowAs = SplitButton;
                actionref(Disconnect_Promoted; Disconnect) { }
            }
        }
    }
    var
        HostName: Text;
        Port: Integer;
        UserName: Text;
        Password: Text;
        SourceFile: Text;
        DestinationFile: Text;
        WorkingDirectory: Text;
        NewDirectory: Text;

    local procedure TestSftpClientPassword()
    var
        SFTPOperationResponse: Codeunit "SFTP Operation Response";
    begin
        SFTPOperationResponse := SFTPClient.Initialize(HostName, Port, UserName, Password);
        if SFTPOperationResponse.IsError() then
            Error(SFTPOperationResponse.GetError());
        ShowException(SFTPClient.GetWorkingDirectory(WorkingDirectory));
        if NewDirectory = '' then
            NewDirectory := WorkingDirectory;
    end;

    local procedure TestSftpClientPrivateKey()
    var
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        SFTPOperationResponse: Codeunit "SFTP Operation Response";
        SFTPClientImplementation: Codeunit "SFTP Client Implementation";
    begin
        FileManagement.BLOBImport(Tempblob, 'PrivateKeyFile');
        SFTPOperationResponse := SFTPClient.Initialize(HostName, Port, UserName, TempBlob.CreateInStream());
        if SFTPOperationResponse.IsError() then
            Error(SFTPOperationResponse.GetError());
        ShowException(SFTPClient.GetWorkingDirectory(WorkingDirectory));
        if NewDirectory = '' then
            NewDirectory := WorkingDirectory;
    end;

    local procedure TestSftpClientPrivateKeyPasspharse()
    var
        FileManagement: Codeunit "File Management";
        PasswordDialogManagement: Codeunit "Password Dialog Management";
        TempBlob: Codeunit "Temp Blob";
        SFTPOperationResponse: Codeunit "SFTP Operation Response";
        Passphrase: SecretText;
    begin
        FileManagement.BLOBImport(Tempblob, 'PrivateKeyFile');
        Passphrase := PasswordDialogManagement.OpenSecretPasswordDialog(true);
        SFTPOperationResponse := SFTPClient.Initialize(HostName, Port, UserName, TempBlob.CreateInStream(), Passphrase);
        if SFTPOperationResponse.IsError() then
            Error(SFTPOperationResponse.GetError());
        ShowException(SFTPClient.GetWorkingDirectory(WorkingDirectory));
        if NewDirectory = '' then
            NewDirectory := WorkingDirectory;
    end;

    trigger OnOpenPage()
    begin
        if Port = 0 then
            Port := 22; // Default SFTP port
    end;

    local procedure ShowException(SFTPOperationResponse: Codeunit "SFTP Operation Response")
    var
        ExceptionTypeErr: Label 'Exception type: %1. Message: %2';
        SFTPExceptionTypeUnsetMsg: Label 'SFTP Exception Type is not set. This is a programming error in SFTP Client.';
    begin
        if not SFTPOperationResponse.IsError() then
            exit;
        if SFTPOperationResponse.GetErrorType() = "SFTP Exception Type"::None then
            Message(SFTPExceptionTypeUnsetMsg);
        Error(StrSubstNo(ExceptionTypeErr, SFTPOperationResponse.GetErrorType(), SFTPOperationResponse.GetError()));
    end;

    var
        SFTPClient: Codeunit "SFTP Client";
}