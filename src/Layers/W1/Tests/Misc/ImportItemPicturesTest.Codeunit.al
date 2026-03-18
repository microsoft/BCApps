codeunit 139320 "Import Item Pictures Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Picture] [Import]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        ArchiveFileName: Text;
        IsInitialized: Boolean;
        CannotCreateZIPErr: Label 'ZIP archive file cannot be created.';

    [Test]
    [Scope('OnPrem')]
    procedure UploadTwoPicturesMappedToItemsFromArchiveWithTwo()
    var
        Item: Record Item;
        TempItemPictureBuffer: Record "Item Picture Buffer" temporary;
        TotalCount: Integer;
    begin
        // [GIVEN] Create a ZIP archive add some pictures to the archive
        Initialize();
        ArchiveFileName := CreateZIPArchiveWithPictures();

        // [GIVEN] Create two items with No. correspondiong to picture's file name from archive
        LibraryInventory.CreateItem(Item);
        Item."No." := 'AllowedImage';
        Item.Insert();
        Item."No." := 'Debra Core';
        Item.Insert();

        // [WHEN] Upload pictures from archive to item picture buffer
        TempItemPictureBuffer.LoadZIPFile(ArchiveFileName, TotalCount, false);

        // [THEN] Verify returned count of pictures in the buffer
        Assert.AreEqual(2, TotalCount, 'Total count should be 2.');
        Assert.AreEqual(2, TempItemPictureBuffer.GetAddCount(), 'Add count should be 2.');
        Assert.AreEqual(0, TempItemPictureBuffer.GetReplaceCount(), 'Replace count should be 0.');

        // [WHEN] Import pictures from buffer to Item records
        TempItemPictureBuffer.ImportPictures(false);

        // [THEN] Verify that imported pictures in Item records equal to original pictures from archive
        Assert.AreEqual(2, TempItemPictureBuffer.GetAddedCount(), 'Add count should be 2.');
        Item.Get('AllowedImage');
        Assert.AreEqual(IsNullGuid(Item.Picture.MediaId), false, 'Picture AllowedImage is not imported');
        Item.Get('Debra Core');
        Assert.AreEqual(IsNullGuid(Item.Picture.MediaId), false, 'Picture Debra Core is not imported');

        // Clean up items
        Item.Get('AllowedImage');
        Item.Delete(true);
        Item.Get('Debra Core');
        Item.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UploadOnePictureMappedToItemFromArchiveWithTwo()
    var
        Item: Record Item;
        TempItemPictureBuffer: Record "Item Picture Buffer" temporary;
        TotalCount: Integer;
    begin
        // [GIVEN] Create a ZIP archive add some pictures to the archive
        Initialize();
        ArchiveFileName := CreateZIPArchiveWithPictures();

        // [GIVEN] Create one item with No. corresponding to first picture file name from archive
        // [GIVEN] Item  with No. corresponding to second picture from archive does not exist
        LibraryInventory.CreateItem(Item);
        Item."No." := 'AllowedImage';
        Item.Insert();

        // [WHEN] Upload pictures from archive to item picture buffer
        TempItemPictureBuffer.LoadZIPFile(ArchiveFileName, TotalCount, false);

        // [THEN] Verify returned count of pictures in the buffer
        Assert.AreEqual(1, TotalCount, 'Total count should be 1.');
        Assert.AreEqual(1, TempItemPictureBuffer.GetAddCount(), 'Add count should be 1.');
        Assert.AreEqual(0, TempItemPictureBuffer.GetReplaceCount(), 'Replace count should be 0.');

        // [WHEN] Import pictures from buffer to Item records
        TempItemPictureBuffer.ImportPictures(false);

        // [THEN] Verify that imported pictures in Item records equal to original pictures from archive
        Assert.AreEqual(1, TempItemPictureBuffer.GetAddedCount(), 'Add count should be 1.');
        Item.Get('AllowedImage');
        Assert.AreEqual(IsNullGuid(Item.Picture.MediaId), false, 'Picture AllowedImage is not imported');

        // Clean up items
        Item.Get('AllowedImage');
        Item.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UploadNoPictureMappedToItemFromArchiveWithTwo()
    var
        TempItemPictureBuffer: Record "Item Picture Buffer" temporary;
        TotalCount: Integer;
    begin
        // [GIVEN] Create a ZIP archive add some pictures to the archive
        Initialize();
        ArchiveFileName := CreateZIPArchiveWithPictures();

        // [GIVEN] No items with No. corresponding to picture file name from archive exists

        // [WHEN] Upload pictures from archive to item picture buffer
        TempItemPictureBuffer.LoadZIPFile(ArchiveFileName, TotalCount, false);

        // [THEN] Verify returned count of pictures in the buffer
        Assert.AreEqual(0, TotalCount, 'Total count should be 0.');
        Assert.AreEqual(0, TempItemPictureBuffer.GetAddCount(), 'Add count should be 0.');
        Assert.AreEqual(0, TempItemPictureBuffer.GetReplaceCount(), 'Replace count should be 0.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UploadTwoPicturesmappedToItemsAndReplaceOne()
    var
        Item: Record Item;
        TempItemPictureBuffer: Record "Item Picture Buffer" temporary;
        TotalCount: Integer;
    begin
        // [GIVEN] Create a ZIP archive add some pictures to the archive
        Initialize();
        ArchiveFileName := CreateZIPArchiveWithPictures();

        // [GIVEN] Create two items with No. correspondiong to picture's file name from archive
        LibraryInventory.CreateItem(Item);
        Item."No." := 'AllowedImage';
        Item.Insert();
        Item."No." := 'Debra Core';
        Item.Insert();

        // [WHEN] Upload and import pictures from archive to item picture buffer
        TempItemPictureBuffer.LoadZIPFile(ArchiveFileName, TotalCount, false);
        TempItemPictureBuffer.ImportPictures(false);
        Clear(TempItemPictureBuffer);

        // [WHEN] Upload pictures from archive to item picture buffer again in REPLACE mode
        TempItemPictureBuffer.LoadZIPFile(ArchiveFileName, TotalCount, true);

        // [THEN] Verify count of pictures to replace
        Assert.AreEqual(2, TempItemPictureBuffer.GetReplaceCount(), 'Replace count should be 2.');

        // [WHEN] Import pictures from archive to item picture buffer
        TempItemPictureBuffer.ImportPictures(true);

        // [THEN] Verify count of replaced pictures
        Assert.AreEqual(2, TempItemPictureBuffer.GetReplacedCount(), 'Replaced count should be 2.');

        // Clean up items
        Item.Get('AllowedImage');
        Item.Delete(true);
        Item.Get('Debra Core');
        Item.Delete(true);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreateZIPArchiveWithPictures(): Text
    var
        FileManagement: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        EntryFile: File;
        ArchiveFile: File;
        EntryFileInStream: InStream;
        ArchiveFileOutStream: OutStream;
        ArchiveFileName: Text;
        FileName: array[2] of Text;
        FilePath: Text;
        Index: Integer;
    begin
        ArchiveFileName := FileManagement.ServerTempFileName('zip');
        ArchiveFile.Create(ArchiveFileName);
        ArchiveFile.CreateOutStream(ArchiveFileOutStream);
        DataCompression.CreateZipArchive();
        if ArchiveFileName = '' then
            Error(CannotCreateZIPErr);

        FilePath := LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\ImageAnalysis\';
        FileName[1] := 'AllowedImage.jpg';
        FileName[2] := 'Debra Core.jpg';

        for Index := 1 to ArrayLen(FileName) do begin
            EntryFile.Open(FilePath + FileName[Index]);
            EntryFile.CreateInStream(EntryFileInStream);
            DataCompression.AddEntry(EntryFileInStream, FileName[Index]);
            EntryFile.Close();
        end;

        DataCompression.SaveZipArchive(ArchiveFileOutStream);
        DataCompression.CloseZipArchive();
        ArchiveFile.Close();

        exit(ArchiveFileName);
    end;
}

