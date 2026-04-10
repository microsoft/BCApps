codeunit 139016 "File Mgt. Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [File Management]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        FileMgt: Codeunit "File Management";
        ExpectedFileNotFoundErr: Label 'does not exist.';
        ImportBlobFromServerFailedErr: Label 'Import blob from server failed.';
        ExpectedAlreadyExistsErr: Label 'already exists.';
        FileNotEmptyErr: Label 'Exported file is not empty.';
        TextStringTxt: Label 'This is the text string.';
        BLOBExportTxt: Label 'This is the text string that we want to store in a BLOB field.';
        ServerDirectoryHelper: DotNet Directory;
        [RunOnClient]
        ClientDirectoryHelper: DotNet Directory;
        [RunOnClient]
        ClientFileHelper: DotNet File;
        ServerPathHelper: DotNet Path;
        [RunOnClient]
        ClientPathHelper: DotNet Path;
        Initialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure BlobExport()
    var
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text;
        BLOBContent: Text;
    begin
        Initialize();

        // Setup
        WriteToBlob(TempBlob, BLOBExportTxt);

        // Exercise
        ClientFileName := FileMgt.BLOBExport(TempBlob, 'Default.txt', false);

        // Verify
        BLOBContent := BLOBExportTxt; // Assign to Text to make Assert.AreEqual work
        Assert.IsTrue(TempBlob.HasValue(), 'The blob field does not contain anything.');
        Assert.AreEqual(ClientFileHelper.ReadAllText(ClientFileName), BLOBContent,
          'The file content doesn''t match what was written to the BLOB');

        // Cleanup
        DeleteClientFile(ClientFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetServerTempFile()
    var
        ServerTempFile: Text;
    begin
        Initialize();
        ServerTempFile := FileMgt.ServerTempFileName('');

        Assert.IsTrue(StrLen(ServerTempFile) > 0, 'The server temp file cannot be empty.');
        Assert.IsTrue(ServerDirectoryHelper.Exists(ServerPathHelper.GetDirectoryName(ServerTempFile)),
          'The directory does not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetToFilterTextDoc()
    var
        "Filter": Text;
    begin
        Initialize();

        Filter := FileMgt.GetToFilterText('Movie Files (*.avi)|*.avi', '');
        Assert.AreEqual('Movie Files (*.avi)|*.avi', Filter, 'Filter is not the expected one');

        Filter := FileMgt.GetToFilterText('', 'filename.doc');
        Assert.IsTrue(StrPos(Filter, '*.doc)|*.doc') > 0, 'Could not identify filter for DOC file type');

        Filter := FileMgt.GetToFilterText('', 'filename.docx');
        Assert.IsTrue(StrPos(Filter, '|*.docx;*.doc') > 0, 'Filter for DOCX file type did not include both *.doc and *.docx');

        Filter := FileMgt.GetToFilterText('', 'filename.xls');
        Assert.IsTrue(StrPos(Filter, '*.xls)|*.xls') > 0, 'Could not identify filter for XLS file type');

        Filter := FileMgt.GetToFilterText('', 'filename.xlsx');
        Assert.IsTrue(StrPos(Filter, '|*.xlsx;*.xls') > 0, 'Filter for XLSX file type did not include both *.xls and *.xlsx');

        Filter := FileMgt.GetToFilterText('', 'filename.txt');
        Assert.IsTrue(StrPos(Filter, '*.txt)|*.txt') > 0, 'Could not identify filter for TXT file type');

        Filter := FileMgt.GetToFilterText('', 'filename.htm');
        Assert.IsTrue(StrPos(Filter, '*.htm)|*.htm') > 0, 'Could not identify filter for HTM file type');

        Filter := FileMgt.GetToFilterText('', 'filename.xml');
        Assert.IsTrue(StrPos(Filter, '*.xml)|*.xml') > 0, 'Could not identify filter for XML file type');

        Filter := FileMgt.GetToFilterText('', 'filename.xsd');
        Assert.IsTrue(StrPos(Filter, '*.xsd)|*.xsd') > 0, 'Could not identify filter for XSD file type');

        Filter := FileMgt.GetToFilterText('', 'filename.xslt');
        Assert.IsTrue(StrPos(Filter, '*.xslt)|*.xslt') > 0, 'Could not identify filter for XSLT file type');

        Filter := FileMgt.GetToFilterText('', 'filename.rdl');
        Assert.IsTrue(StrPos(Filter, '*.rdl;*.rdlc)|*.rdl') > 0, 'Could not identify filter for RDL file type');

        Filter := FileMgt.GetToFilterText('', 'filename.rdlc');
        Assert.IsTrue(StrPos(Filter, '|*.rdl;*.rdlc') > 0, 'Filter for RDLC file type did not include both *.rdl and *.rdlc');
    end;

    [Normal]
    local procedure CheckClientDirectoryExist(FileName: Text): Boolean
    begin
        if FileName = '' then
            exit(false);

        exit(ClientDirectoryHelper.Exists(ClientPathHelper.GetDirectoryName(FileName)));
    end;

    [Normal]
    local procedure CreateClientFile(): Text
    begin
        exit(ClientPathHelper.GetTempFileName());
    end;

    [Normal]
    local procedure DeleteClientFile(FileName: Text)
    begin
        ClientFileHelper.Delete(FileName);
    end;

    local procedure WriteToBlob(var TempBlob: Codeunit "Temp Blob"; Content: Text)
    var
        OStream: OutStream;
        BigStr: BigText;
    begin
        Clear(BigStr);
        Clear(TempBlob);
        BigStr.AddText(Content);
        TempBlob.CreateOutStream(OStream);
        BigStr.Write(OStream);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSafeFileName()
    var
        PathHelper: DotNet Path;
        DotNetString: DotNet String;
        FileName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379537] GetSafeFileName should remove invalid characters (colon, etc) in the file name
        Initialize();

        DotNetString := DotNetString.String(PathHelper.GetInvalidFileNameChars());

        FileName := DotNetString + 'Default.docx';

        FileName := FileMgt.GetSafeFileName(FileName);

        Assert.AreEqual('Default.docx', FileName, '');
    end;

    [Normal]
    local procedure Initialize()
    begin
        if not Initialized then
            Initialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileNameNonBlank()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        Initialize();
        FileName := FileManagement.GetFileName('c:\temp\Test001.txt');
        Assert.AreEqual('Test001.txt', FileName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileNameBlank()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        Initialize();
        FileName := FileManagement.GetFileName('');
        Assert.AreEqual('', FileName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileNameNoExtension()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        Initialize();
        FileName := FileManagement.GetFileName('c:\temp\Test001');
        Assert.AreEqual('Test001', FileName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileNameWithSpaces()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        Initialize();
        FileName := FileManagement.GetFileName('c:\temp\Test 001.txt');
        Assert.AreEqual('Test 001.txt', FileName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDirectory()
    var
        ClientFileName: Text;
        PathName: Text;
    begin
        Initialize();

        ClientFileName := CreateClientFile();
        PathName := FileMgt.GetDirectoryName(ClientFileName);
        Assert.IsTrue(CheckClientDirectoryExist(PathName), 'Path did not exist.');

        // Cleanup
        DeleteClientFile(ClientFileName);

        ClientFileName := 'clientfilenamewithoutpath.txt';
        PathName := FileMgt.GetDirectoryName(ClientFileName);
        Assert.AreEqual('', PathName, 'Path should be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDirectoryFileNameBlank()
    var
        PathName: Text;
    begin
        Initialize();

        PathName := FileMgt.GetDirectoryName('');
        Assert.AreEqual('', PathName, 'Path should be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportTempBlobFileNotFoundTest()
    var
        TempBlob: Codeunit "Temp Blob";
        TempFileName: Text;
    begin
        Initialize();
        TempFileName := FileMgt.ServerTempFileName('');
        asserterror FileMgt.BLOBImportFromServerFile(TempBlob, TempFileName);
        Assert.ExpectedError(ExpectedFileNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportExportBlobHasTheSameContentTest()
    var
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        ExportFileName: Text;
        TextArray: array[10] of Text[30];
    begin
        Initialize();
        ExportFileName := FileMgt.ServerTempFileName('');
        CreateExpectedTexts(TextArray, 2);
        FileName := CreateTextFileOnServer(TextArray, 2);
        FileMgt.BLOBImportFromServerFile(TempBlob, FileName);
        FileMgt.BLOBExportToServerFile(TempBlob, ExportFileName);
        Assert.IsTrue(ValidateExportedServerFile(ExportFileName, TextArray, 2), ImportBlobFromServerFailedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBlobToServerToExistingFileTest()
    var
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        TextArray: array[10] of Text[30];
    begin
        Initialize();
        CreateExpectedTexts(TextArray, 1);
        FileName := CreateTextFileOnServer(TextArray, 1);
        asserterror FileMgt.BLOBExportToServerFile(TempBlob, FileName);
        Assert.ExpectedError(ExpectedAlreadyExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportEmptyBlobToServer()
    var
        TempBlob: Codeunit "Temp Blob";
        ExportedFile: File;
        FileName: Text;
        TempText: Text[1024];
    begin
        Initialize();
        FileName := FileMgt.ServerTempFileName('');
        FileMgt.BLOBExportToServerFile(TempBlob, FileName);
        ExportedFile.WriteMode(false);
        ExportedFile.TextMode(true);
        ExportedFile.Open(FileName);
        Assert.IsTrue(ExportedFile.Read(TempText) = 0, FileNotEmptyErr);
        ExportedFile.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportInstreamToServerFile()
    var
        TempBlob: Codeunit "Temp Blob";
        File: File;
        InStream: InStream;
        OutStream: OutStream;
        Content: Text;
        FileName: Text;
    begin
        Initialize();
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('hello world');
        TempBlob.CreateInStream(InStream);
        FileName := FileMgt.InstreamExportToServerFile(InStream, 'html');
        File.Open(FileName);
        File.CreateInStream(InStream);
        InStream.ReadText(Content);
        Assert.AreEqual('hello world', Content, 'file content does not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateAndWriteToServerFile()
    var
        File: File;
        InStream: InStream;
        Content: Text;
        FileName: Text;
    begin
        Initialize();
        FileName := FileMgt.CreateAndWriteToServerFile('hello world', 'html');
        File.Open(FileName);
        File.CreateInStream(InStream);
        InStream.ReadText(Content);
        Assert.AreEqual('hello world', Content, 'file content does not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetServerDirectoryFilesListInclSubDirs()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        File: File;
        DirectoryPath: Text;
        Names: array[5] of Text;
        Index: Integer;
    begin
        // [SCERNARIO] A list of every file under a directory is returned including subdirectories
        DirectoryPath := FileMgt.ServerCreateTempSubDirectory();
        FileMgt.ServerCreateDirectory(DirectoryPath + '\Temp');

        Names[1] := DirectoryPath + '\file1.txt';
        Names[2] := DirectoryPath + '\file2.txt';
        Names[3] := DirectoryPath + '\file3.txt';
        Names[4] := DirectoryPath + '\Temp\file1.txt';
        Names[5] := DirectoryPath + '\Temp\file2.txt';

        // [GIVEN] 3 files are contained directly under the folder
        File.Create(Names[1]);
        File.Close();

        File.Create(Names[2]);
        File.Close();

        File.Create(Names[3]);
        File.Close();

        // [GIVEN] 2 files are contained in a subfolder
        File.Create(Names[4]);
        File.Close();

        File.Create(Names[5]);
        File.Close();

        // [WHEN] GetAllFilesUnderDirectory function is called
        FileMgt.GetServerDirectoryFilesListInclSubDirs(TempNameValueBuffer, DirectoryPath);

        // [THEN] 5 files are found
        Assert.RecordCount(TempNameValueBuffer, 5);

        TempNameValueBuffer.FindSet();
        for Index := 1 to 5 do begin
            Assert.AreEqual(TempNameValueBuffer.Name, Names[Index], 'name was different');
            TempNameValueBuffer.Next();
        end;

        // Clean up
        FileMgt.DeleteServerFile(DirectoryPath + '\Temp\file1.txt');
        FileMgt.DeleteServerFile(DirectoryPath + '\Temp\file2.txt');
        FileMgt.DeleteServerFile(DirectoryPath + '\file1.txt');
        FileMgt.DeleteServerFile(DirectoryPath + '\file2.txt');
        FileMgt.DeleteServerFile(DirectoryPath + '\file3.txt');
    end;

    local procedure CreateTextFileOnServerWithExtension(TextArray: array[10] of Text[30]; NoOfElements: Integer; FileExtension: Text[5]) FileName: Text
    var
        FileManagement: Codeunit "File Management";
        File: File;
        Counter: Integer;
    begin
        FileName := FileManagement.ServerTempFileName(FileExtension);
        File.WriteMode(true);
        File.TextMode(true);
        File.Create(FileName);
        for Counter := 1 to NoOfElements do
            File.Write(TextArray[Counter]);
        File.Close();
    end;

    local procedure CreateTextFileOnServer(TextArray: array[10] of Text[30]; NoOfElements: Integer) FileName: Text
    begin
        FileName := CreateTextFileOnServerWithExtension(TextArray, NoOfElements, '');
    end;

    local procedure ValidateExportedServerFile(FileName: Text; TextArray: array[10] of Text[30]; NoOfElements: Integer): Boolean
    var
        StreamReader: DotNet StreamReader;
        Result: Boolean;
    begin
        StreamReader := StreamReader.StreamReader(FileName);
        Result := ValidateExportedFile(StreamReader, TextArray, NoOfElements);
        StreamReader.Close();
        exit(Result);
    end;

    local procedure ValidateExportedFile(var StreamReader: DotNet StreamReader; TextArray: array[10] of Text[30]; NoOfElements: Integer): Boolean
    var
        ReadData: Text[30];
        Counter: Integer;
    begin
        Counter := 1;
        while Counter <= NoOfElements do begin
            ReadData := StreamReader.ReadLine();
            if (ReadData = '') or (ReadData <> TextArray[Counter]) then
                exit(false);
            Counter := Counter + 1
        end;
        exit(Counter > NoOfElements);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsValidFileNameTest()
    var
        FileName: Text;
    begin
        FileName := 'WithoutExtension';
        Assert.IsTrue(FileMgt.IsValidFileName(FileName), 'File name without extension should be valid.');

        FileName := 'WithExtension.txt';
        Assert.IsTrue(FileMgt.IsValidFileName(FileName), 'File name with extension should be valid.');

        FileName := 'WithExtension.ext1.txt';
        Assert.IsTrue(FileMgt.IsValidFileName(FileName), 'File name with two dots should be valid.');

        FileName := '';
        Assert.IsFalse(FileMgt.IsValidFileName(FileName), 'Empty file name.');

        FileName := '*';
        Assert.IsFalse(FileMgt.IsValidFileName(FileName), 'File name of one invalid char.');

        FileName := '*InvalidAtStart';
        Assert.IsFalse(FileMgt.IsValidFileName(FileName), 'File name with invalid char at the beginning should not be valid.');

        FileName := 'InvalidAtEnd?';
        Assert.IsFalse(FileMgt.IsValidFileName(FileName), 'File name with invalid char at the end should not be valid.');

        FileName := 'Invalid?InMiddle';
        Assert.IsFalse(FileMgt.IsValidFileName(FileName), 'File name with invalid char in the middle should not be valid.');
    end;

    [Test]
    procedure AppendFileNameWithIndex()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 401532] COD 419 "File Management".AppendFileNameWithIndex() unit tests
        Assert.AreEqual(' (0)', FileMgt.AppendFileNameWithIndex('', 0), '');
        Assert.AreEqual('file (1)', FileMgt.AppendFileNameWithIndex('file', 1), '');
        Assert.AreEqual('file name (2)', FileMgt.AppendFileNameWithIndex('file name', 2), '');
        Assert.AreEqual('c:\temp\file name (3)', FileMgt.AppendFileNameWithIndex('c:\temp\file name', 3), '');

        Assert.AreEqual(' (10).txt', FileMgt.AppendFileNameWithIndex('.txt', 10), '');
        Assert.AreEqual('file (11).txt', FileMgt.AppendFileNameWithIndex('file.txt', 11), '');
        Assert.AreEqual('file name (12).txt', FileMgt.AppendFileNameWithIndex('file name.txt', 12), '');
        Assert.AreEqual('c:\temp\file name (13).txt', FileMgt.AppendFileNameWithIndex('c:\temp\file name.txt', 13), '');

        Assert.AreEqual('.txt (20).pdf', FileMgt.AppendFileNameWithIndex('.txt.pdf', 20), '');
        Assert.AreEqual('file.txt (21).pdf', FileMgt.AppendFileNameWithIndex('file.txt.pdf', 21), '');
        Assert.AreEqual('file name.txt (22).pdf', FileMgt.AppendFileNameWithIndex('file name.txt.pdf', 22), '');
        Assert.AreEqual('c:\temp\file name.txt (23).pdf', FileMgt.AppendFileNameWithIndex('c:\temp\file name.txt.pdf', 23), '');
    end;

    local procedure CreateExpectedTexts(var TextArray: array[10] of Text[30]; NoOfElements: Integer)
    var
        Counter: Integer;
    begin
        for Counter := 1 to NoOfElements do
            TextArray[Counter] := TextStringTxt + Format(Counter);
    end;

}
