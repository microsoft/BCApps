page 50100 "SFTP Client - Debug"
{
    Caption = 'SFTP Client - Debug';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
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
            }
            group(FileTransfer)
            {
                Caption = 'File Transfer';
                field(OriginalFile; OriginalFile)
                {
                    ApplicationArea = All;
                    Caption = 'Original File';
                    ToolTip = 'The path of the original file on the SFTP server.';
                }
                field(NewFile; NewFile)
                {
                    ApplicationArea = All;
                    Caption = 'New File';
                    ToolTip = 'The path of the new file on the SFTP server.';
                }
                field(MovedFile; MovedFile)
                {
                    ApplicationArea = All;
                    Caption = 'Moved File';
                    ToolTip = 'The path of the moved file on the SFTP server.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;
                Image = ConfirmAndPrint;
                Caption = 'Test SFTP Client';

                trigger OnAction()
                begin
                    TestSftpClientPassword();
                end;
            }
            action(TestWithPrivateKeysNoPassphrase)
            {
                ApplicationArea = All;
                Image = FiledPosted;
                Caption = 'Test SFTP Client with Private Key (No password)';

                trigger OnAction()
                begin
                    TestSftpClientPrivateKey();
                end;
            }
            action(TestWithPrivateKeysPassphrase)
            {
                ApplicationArea = All;
                Image = SerialNo;
                Caption = 'Test SFTP Client with Private Key Passphrase';

                trigger OnAction()
                begin
                    TestSftpClientPrivateKeyPasspharse();
                end;
            }
        }
        area(Promoted)
        {
            group(Test)
            {
                ShowAs = SplitButton;
                actionref(ActionName_Promoted; ActionName) { }
                actionref(TestWithPrivateKeysNoPassphrase_Promoted; TestWithPrivateKeysNoPassphrase) { }
                actionref(TestWithPrivateKeysPassphrase_Promoted; TestWithPrivateKeysPassphrase) { }
            }
        }
    }
    var
        HostName: Text;
        Port: Integer;
        UserName: Text;
        Password: Text;
        OriginalFile: Text;
        NewFile: Text;
        MovedFile: Text;

    local procedure TestSftpClientPassword()
    begin
        SFTPClient.Initialize(HostName, Port, UserName, Password);
        Common();
    end;

    local procedure TestSftpClientPrivateKey()
    var
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
    begin
        FileManagement.BLOBImport(Tempblob, 'PrivateKeyFile');
        SFTPClient.Initialize(HostName, Port, UserName, TempBlob.CreateInStream());
        Common();
    end;

    local procedure TestSftpClientPrivateKeyPasspharse()
    var
        FileManagement: Codeunit "File Management";
        PasswordDialogManagement: Codeunit "Password Dialog Management";
        TempBlob: Codeunit "Temp Blob";
        Passphrase: SecretText;
    begin
        FileManagement.BLOBImport(Tempblob, 'PrivateKeyFile');
        Passphrase := PasswordDialogManagement.OpenSecretPasswordDialog(true);
        SFTPClient.Initialize(HostName, Port, UserName, TempBlob.CreateInStream(), Passphrase);
        Common();
    end;

    local procedure Common()
    var
        Instream: InStream;
        Text: Text;
    begin
        SFTPClient.GetFileAsStream(OriginalFile, InStream);
        SFTPClient.PutFileStream(NewFile, InStream);
        Instream.Position := 1; // Reset the position of the stream to read from the beginning
        Instream.ReadText(Text);
        Message('Content of the original file: %1', Text);
        Message('NewFile Exists: %1', SFTPClient.FileExists(NewFile));
        SFTPClient.MoveFile(NewFile, MovedFile);
        SFTPClient.DeleteFile(MovedFile);
        SFTPClient.Disconnect();
    end;

    var
        SFTPClient: Codeunit "SFTP Client";
}