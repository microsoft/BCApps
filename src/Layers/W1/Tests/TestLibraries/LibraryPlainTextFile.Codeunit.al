codeunit 131342 "Library - Plain Text File"
{

    trigger OnRun()
    begin
    end;

    var
        FileManagement: Codeunit "File Management";
        InnerFile: File;

    procedure Create(Extension: Text): Text
    var
        FileFullPath: Text;
    begin
        FileFullPath := FileManagement.ServerTempFileName(Extension);

        InnerFile.TextMode(true);
        InnerFile.WriteMode(true);
        InnerFile.Create(FileFullPath);

        exit(FileFullPath);
    end;

    procedure Close()
    begin
        InnerFile.Close();
    end;

    procedure AddLine(LineText: Text)
    begin
        InnerFile.Write(LineText);
    end;
}

