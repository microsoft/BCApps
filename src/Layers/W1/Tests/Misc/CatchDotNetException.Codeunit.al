codeunit 132567 "Catch DotNet Exception"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Base64] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure ReadDataFromCache()
    var
        TempBlob: Codeunit "Temp Blob";
        ReadMasterDataFromCache: Codeunit "Read Master Data from Cache";
        InputStream: InStream;
        Content: Text;
        ServerFileName: Text;
    begin
        // Setup
        ServerFileName := CreateServerFile();
        ConfigureMasterDataSetup(ServerFileName);

        // Pre-Exercise
        Commit();

        // Exercise
        ReadMasterDataFromCache.Run();
        ReadMasterDataFromCache.GetTempBlob(TempBlob);

        // Pre-Verify
        TempBlob.CreateInStream(InputStream);
        InputStream.Read(Content);

        // Verify
        Assert.AreEqual(ReadFileContentAsBase64(ServerFileName), Content, '');
    end;

    local procedure CreateServerFile() ServerFileName: Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        OutputStream: OutStream;
    begin
        ServerFileName := FileMgt.ServerTempFileName('txt');

        TempBlob.CreateOutStream(OutputStream);
        OutputStream.Write(LibraryUtility.GenerateRandomText(1024));

        FileMgt.BLOBExportToServerFile(TempBlob, ServerFileName);
    end;

    local procedure ConfigureMasterDataSetup(FileName: Text)
    var
        MasterDataSetupSample: Record "Master Data Setup Sample";
        FileMgt: Codeunit "File Management";
    begin
        MasterDataSetupSample.DeleteAll();

        MasterDataSetupSample.Name := CopyStr(FileMgt.GetFileName(FileName), 1, MaxStrLen(MasterDataSetupSample.Name));
        MasterDataSetupSample.Path := CopyStr(FileMgt.GetDirectoryName(FileName), 1, MaxStrLen(MasterDataSetupSample.Path));
        MasterDataSetupSample.Insert();
    end;

    local procedure ReadFileContentAsBase64(FileName: Text): Text
    var
        Convert: DotNet Convert;
        File: DotNet File;
    begin
        exit(Convert.ToBase64String(File.ReadAllBytes(FileName)));
    end;

}