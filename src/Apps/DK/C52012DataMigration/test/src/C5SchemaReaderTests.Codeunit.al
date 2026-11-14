// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information. 
// ------------------------------------------------------------------------------------------------

codeunit 148007 "C5 Schema Reader Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    trigger OnRun();
    begin
        // [FEATURE] [C5 Data Migration]
    end;

    [Test]
    procedure TestProcessZipFile()
    var
        C5SchemaParameters: Record "C5 Schema Parameters";
        C5SchemaReader: Codeunit "C5 Schema Reader";
    begin
        // [SCENARIO] C5 files are in the root directory of the zip. The zip is extracted and the right values are read from the definition file

        // [GIVEN] The zip file exists
        CopyZipFileToBlob('Data.zip', C5SchemaParameters);

        // [WHEN] Schema Reader codeunit is run
        Codeunit.Run(Codeunit::"C5 Schema Reader", C5SchemaParameters);

        // [THEN] Then the Codeunit C5SchemaReader returns the right values from the definition file
        Assert.AreEqual(C5SchemaReader.GetNumberOfAccounts(), 247, 'A different number of Accounts was expected');
        Assert.AreEqual(C5SchemaReader.GetNumberOfItems(), 45, 'A different number of Items was expected');
        Assert.AreEqual(C5SchemaReader.GetNumberOfVendors(), 14, 'A different number of Vendors was expected');
        Assert.AreEqual(C5SchemaReader.GetNumberOfCustomers(), 28, 'A different number Customers was expected');
    end;

    [Test]
    procedure TestFilesAreIncludedInSubfolder()
    var
        C5SchemaParameters: Record "C5 Schema Parameters";
        C5SchemaReader: Codeunit "C5 Schema Reader";
    begin
        // [SCENARIO] C5 files are under a subdirectory of the zip. The zip is extracted and the right values are read from the definition file

        // [GIVEN] The zip file exists
        CopyZipFileToBlob('FilesInSubfolder.zip', C5SchemaParameters);

        // [WHEN] Schema Reader codeunit is run
        Codeunit.Run(Codeunit::"C5 Schema Reader", C5SchemaParameters);

        // [THEN] Then the Codeunit C5SchemaReader returns the right values from the definition file
        Assert.AreEqual(C5SchemaReader.GetNumberOfAccounts(), 247, 'A different number of Accounts was expected');
        Assert.AreEqual(C5SchemaReader.GetNumberOfItems(), 45, 'A different number of Items was expected');
        Assert.AreEqual(C5SchemaReader.GetNumberOfVendors(), 14, 'A different number of Vendors was expected');
        Assert.AreEqual(C5SchemaReader.GetNumberOfCustomers(), 28, 'A different number Customers was expected');
    end;

    [Test]
    procedure TestFilesAreMissingFromTheZip()
    var
        SchemaParameters: Record "C5 Schema Parameters";
        C5SchemaReader: Codeunit "C5 Schema Reader";
    begin
        // [SCENARIO] Files might be missing from the zip file, but not the definition file. 

        // [GIVEN] The zip file exists and some files are missing
        CopyZipFileToBlob('FilesMissing.zip', SchemaParameters);

        // [WHEN] Schema Reader codeunit is run
        Codeunit.Run(Codeunit::"C5 Schema Reader", SchemaParameters);

        // [THEN] Then the Codeunit C5SchemaReader returns the right values from the definition file
        Assert.AreEqual(C5SchemaReader.GetNumberOfAccounts(), 247, 'A different number of Accounts was expected');
        Assert.AreEqual(C5SchemaReader.GetNumberOfItems(), 45, 'A different number of Items was expected');
        Assert.AreEqual(C5SchemaReader.GetNumberOfVendors(), 14, 'A different number of Vendors was expected');
        Assert.AreEqual(C5SchemaReader.GetNumberOfCustomers(), 28, 'A different number Customers was expected');

        // [GIVEN] The zip file exists and the definition file is missing
        CopyZipFileToBlob('DefFileMissing.zip', SchemaParameters);

        // [WHEN] Schema Reader codeunit is run
        // [THEN] An error is expected
        asserterror Codeunit.Run(Codeunit::"C5 Schema Reader", SchemaParameters);
        Assert.ExpectedError('Oops, it seems the definition file (exp00000.def) was missing from the zip file.');
    end;

    [Test]
    procedure TestZipFileMissing()
    var
        C5SchemaParameters: Record "C5 Schema Parameters";
    begin
        // [SCENARIO] A "nice" error should thrown if the zip file does not exist

        // [WHEN] ProcessZipFile is called
        // [THEN] A "nice" error is thrown
        CopyZipFileToBlob('Non_existing_file.zip', C5SchemaParameters);

        // [WHEN] Schema Reader codeunit is run
        // [THEN] An error is expected
        asserterror Codeunit.Run(Codeunit::"C5 Schema Reader", C5SchemaParameters);
        Assert.ExpectedError('Zip File Blob is empty in C5SchemaParameters.');
    end;

    [Test]
    procedure TestMissingArchiveClearsPreviousBlob()
    var
        C5SchemaParameters: Record "C5 Schema Parameters";
    begin
        CopyZipFileToBlob('Data.zip', C5SchemaParameters);
        C5SchemaParameters.CalcFields("Zip File Blob");
        Assert.IsTrue(C5SchemaParameters."Zip File Blob".HasValue(), 'The initial archive must be loaded.');

        CopyZipFileToBlob('Non_existing_file.zip', C5SchemaParameters);

        asserterror Codeunit.Run(Codeunit::"C5 Schema Reader", C5SchemaParameters);
        Assert.ExpectedError('Zip File Blob is empty in C5SchemaParameters.');
    end;

    [Test]
    procedure TestArchiveCanBeReloadedWithoutChangingBytes()
    var
        C5SchemaParameters: Record "C5 Schema Parameters";
        Base64Convert: Codeunit "Base64 Convert";
        ArchiveStream: InStream;
        OriginalArchive: Text;
    begin
        CopyZipFileToBlob('Data.zip', C5SchemaParameters);
        C5SchemaParameters.CalcFields("Zip File Blob");
        C5SchemaParameters."Zip File Blob".CreateInStream(ArchiveStream);
        OriginalArchive := Base64Convert.ToBase64(ArchiveStream);

        CopyZipFileToBlob('FilesMissing.zip', C5SchemaParameters);
        CopyZipFileToBlob('Data.zip', C5SchemaParameters);

        C5SchemaParameters.CalcFields("Zip File Blob");
        C5SchemaParameters."Zip File Blob".CreateInStream(ArchiveStream);
        Assert.AreEqual(OriginalArchive, Base64Convert.ToBase64(ArchiveStream), 'Reloading must retain every archive byte.');
    end;

    local procedure CopyZipFileToBlob(FileName: Text; var C5SchemaParametersOut: Record "C5 Schema Parameters")
    var
        ZipInStream: InStream;
        BlobOutStream: OutStream;
        ResourceNames: List of [Text];
    begin
        C5SchemaParametersOut.DeleteAll();
        ResourceNames := NavApp.ListResources();
        if ResourceNames.Contains(FileName) then begin
            NavApp.GetResource(FileName, ZipInStream);

            C5SchemaParametersOut.GetSingleInstance();
            C5SchemaParametersOut."Zip File Blob".CreateOutStream(BlobOutStream);
            CopyStream(BlobOutStream, ZipInStream);
            C5SchemaParametersOut.Modify();
            Commit();
        end;
    end;
}
