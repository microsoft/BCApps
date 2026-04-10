namespace System.IO;

using System.Utilities;

codeunit 8620 "Config. Package - Import"
{

    trigger OnRun()
    begin
    end;

    var
        PathIsEmptyErr: Label 'You must enter a file path.';
        ErrorsImportingPackageErr: Label '%1 errors occurred when importing %2 package.', Comment = '%1 = No. of errors, %2 = Package Code';
        PathIsTooLongErr: Label 'The path cannot be longer than %1 characters.', Comment = '%1 = Max no. of characters';

    [Scope('OnPrem')]
    procedure ImportAndApplyRapidStartPackage(PackageFileLocation: Text)
    var
        TempConfigSetup: Record "Config. Setup" temporary;
    begin
        ImportRapidStartPackage(PackageFileLocation, TempConfigSetup);
        ApplyRapidStartPackage(TempConfigSetup);
    end;

    [Scope('OnPrem')]
    procedure ImportRapidStartPackage(PackageFileLocation: Text; var TempConfigSetup: Record "Config. Setup" temporary)
    var
        DecompressedFileName: Text;
        FileLocation: Text[250];
    begin
        if PackageFileLocation = '' then
            Error(PathIsEmptyErr);

        if StrLen(PackageFileLocation) > MaxStrLen(TempConfigSetup."Package File Name") then
            Error(PathIsTooLongErr, MaxStrLen(TempConfigSetup."Package File Name"));

        FileLocation :=
          CopyStr(PackageFileLocation, 1, MaxStrLen(TempConfigSetup."Package File Name"));

        TempConfigSetup.Init();
        TempConfigSetup.Insert();
        TempConfigSetup."Package File Name" := FileLocation;
        DecompressedFileName := TempConfigSetup.DecompressPackage(false);

        TempConfigSetup.SetHideDialog(true);
        TempConfigSetup.ReadPackageHeader(DecompressedFileName);
        TempConfigSetup.ImportPackage(DecompressedFileName);
    end;

    procedure ApplyRapidStartPackage(var TempConfigSetup: Record "Config. Setup" temporary)
    var
        ErrorCount: Integer;
    begin
        ErrorCount := TempConfigSetup.ApplyPackages();
        if ErrorCount > 0 then
            Error(ErrorsImportingPackageErr, ErrorCount, TempConfigSetup."Package Code");
        TempConfigSetup.ApplyAnswers();
    end;

    procedure ImportAndApplyRapidStartPackageStream(var TempBlob: Codeunit "Temp Blob")
    var
        TempConfigSetup: Record "Config. Setup" temporary;
    begin
        ImportRapidStartPackageStream(TempBlob, TempConfigSetup);
        ApplyRapidStartPackage(TempConfigSetup);
    end;

    procedure ImportRapidStartPackageStream(var TempBlob: Codeunit "Temp Blob"; var TempConfigSetup: Record "Config. Setup" temporary)
    var
        TempBlobUncompressed: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        InStream: InStream;
    begin
        if TempConfigSetup.Get('ImportRS') then
            TempConfigSetup.Delete();
        TempConfigSetup.Init();
        TempConfigSetup."Primary Key" := 'ImportRS';
        TempConfigSetup."Package File Name" := 'ImportRapidStartPackageFromStream';
        TempConfigSetup.Insert();
        // TempBlob contains the compressed .rapidstart file
        // Decompress the file and put into the TempBlobUncompressed blob
        TempConfigSetup.DecompressPackageToBlob(TempBlob, TempBlobUncompressed);
        RecordRef.GetTable(TempConfigSetup);
        TempBlobUncompressed.ToRecordRef(RecordRef, TempConfigSetup.FieldNo("Package File"));
        RecordRef.SetTable(TempConfigSetup);
        TempConfigSetup."Package File".CreateInStream(InStream);

        TempConfigSetup.SetHideDialog(true);
        TempConfigSetup.ReadPackageHeaderFromStream(InStream);
        TempConfigSetup.ImportPackageFromStream(InStream);
    end;
}

