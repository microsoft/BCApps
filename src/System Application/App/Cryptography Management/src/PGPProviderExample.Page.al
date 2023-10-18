namespace System.Security.Encryption;
using System;
using System.Text;
using System.Utilities;

page 1499 "PGP Provider Example"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field(NameSource; Input)
                {
                    MultiLine = true;
                    ApplicationArea = All;
                    Caption = 'Input';
                    ToolTip = 'Specifies 1';
                }
                field(NameSource2; Output)
                {
                    MultiLine = true;
                    ApplicationArea = All;
                    Caption = 'Output';
                    ToolTip = 'Specifies 2';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Encrypt)
            {
                ApplicationArea = All;
                Caption = 'Encrypt';
                Image = EncryptionKeys;
                ToolTip = 'Specif';

                trigger OnAction()
                var
                    ByteArray: Dotnet Array;
                begin
                    upload();
                    ByteArray := PGPProvider.Encrypt(Convert.FromBase64String(Base64Convert.ToBase64(Input)), Array2);
                    Output := Convert.ToBase64String(ByteArray);
                    Input := '';
                end;
            }
            action(Decrypt)
            {
                ApplicationArea = All;
                Caption = 'Decrypt';
                Image = EncryptionKeys;
                ToolTip = 'Specif';

                trigger OnAction()
                var
                    ByteArray: Dotnet Array;
                begin
                    upload();
                    ByteArray := PGPProvider.Decrypt(Convert.FromBase64String(Input), Array2, '');
                    Output := Base64Convert.FromBase64(Convert.ToBase64String(ByteArray)); //Encoding.UTF8().GetString(ByteArray);
                    Input := '';
                end;
            }
        }
    }

    local procedure upload()
    var
        FileName: Text;
        SelectFileTxt: Label 'Select a certificate file';
    begin
        FileName := BLOBImportWithFilter(TempBlob, SelectFileTxt, FileName, '', '');
        if FileName = '' then
            Error('');

        ReadCertFromBlob();


    end;

    procedure BLOBImportWithFilter(var TempBlob2: Codeunit "Temp Blob"; DialogCaption: Text; Name: Text; FileFilter: Text; ExtFilter: Text): Text
    var
        NVInStream: InStream;
        NVOutStream: OutStream;
        UploadResult: Boolean;
        ErrorMessage: Text;
    begin
        // ExtFilter examples: 'csv,txt' if you only accept *.csv and *.txt or '*.*' if you accept any extensions
        ClearLastError();

        // There is no way to check if NVInStream is null before using it after calling the
        // UPLOADINTOSTREAM therefore if result is false this is the only way we can throw the error.
        UploadResult := UploadIntoStream(DialogCaption, '', FileFilter, Name, NVInStream);
        if UploadResult then begin
            TempBlob2.CreateOutStream(NVOutStream);
            CopyStream(NVOutStream, NVInStream);
            exit(Name);
        end;
        ErrorMessage := GetLastErrorText;
        if ErrorMessage <> '' then
            Error(ErrorMessage);

        exit('');
    end;

    [TryFunction]
    local procedure ReadCertFromBlob()
    var
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        Array2 := Convert.FromBase64String(Base64Convert.ToBase64(InStream));
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        Input, Output : Text;
        PGPProvider: DotNet PGPProvider;
        Array2: DotNet Array;
        Base64Convert: Codeunit "Base64 Convert";
        Convert: DotNet Convert;
}