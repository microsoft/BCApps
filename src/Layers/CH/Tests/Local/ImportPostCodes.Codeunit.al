codeunit 144010 "Import Post Codes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        ImportSuccessfulMsg: Label 'The new post codes have been successfully imported.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Import Post Codes");
        InsertNumericPostCodes();
        Commit();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ImportOnePostCode()
    var
        PostCode: Record "Post Code";
        ImportPostCodes: Report "Import Post Codes";
        TempFileName: Text;
        NewPostCode: Text;
        NewCity: Text;
        NewCounty: Text;
    begin
        // [SCENARIO 208075] Report "Import Post Codes" have to create post code from .csv file
        Initialize();

        // [GIVEN] .csv file with post code "PC"
        CreatePostCodeFile(NewPostCode, NewCity, NewCounty, TempFileName);

        // [GIVEN] Table "Post Code" doesn't contain record "PC"
        asserterror PostCode.Get(NewPostCode, NewCity);

        // [WHEN] Run "Import post codes"
        ImportPostCodes.InitializeRequest(TempFileName);
        ImportPostCodes.RunModal();

        // [THEN] Post Code "PC" has been imported
        VerifyPostCode(NewPostCode, NewCity, NewCounty);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ImportPostCodesCancelImport()
    var
        PostCode: Record "Post Code";
        ImportPostCodes: Report "Import Post Codes";
        TempFileName: Text;
        NewPostCode: Text;
        NewCity: Text;
        NewCounty: Text;
        NumericPostCodesCount: Integer;
    begin
        Initialize();

        // Setup.
        NumericPostCodesCount := GetNumericPostCodesCount();
        CreatePostCodeFile(NewPostCode, NewCity, NewCounty, TempFileName);

        // Pre-check.
        asserterror PostCode.Get(NewPostCode, NewCity);

        // Exercise.
        ImportPostCodes.InitializeRequest(TempFileName);
        asserterror ImportPostCodes.RunModal();

        // Verify.
        Assert.AreEqual(NumericPostCodesCount, GetNumericPostCodesCount(), 'Number of numeric codes should be the same.');
        asserterror PostCode.Get(NewPostCode, NewCity);
    end;

    local procedure CreatePostCodeFile(var NewPostCode: Text; var NewCity: Text; var NewCounty: Text; var TempFileName: Text)
    var
        PostCode: Record "Post Code";
        FileManagement: Codeunit "File Management";
        Outstream: OutStream;
        File: File;
    begin
        NewPostCode := Format(LibraryRandom.RandIntInRange(1000, 9999));
        NewCity := LibraryUtility.GenerateRandomCode(PostCode.FieldNo(City), DATABASE::"Post Code");
        NewCounty := LibraryUtility.GenerateRandomCode(PostCode.FieldNo(County), DATABASE::"Post Code");
        TempFileName := FileManagement.ServerTempFileName('txt');
        File.Create(TempFileName);
        File.CreateOutStream(Outstream);
        Outstream.WriteText(NewPostCode + ';' + NewCity + ';' + NewCounty + ';;;' + ' ');
        File.Close();
    end;

    local procedure GetNumericPostCodesCount(): Integer
    var
        PostCode: Record "Post Code";
    begin
        PostCode.SetRange(Code, '1000', '9999');
        exit(PostCode.Count);
    end;

    local procedure InsertNumericPostCodes()
    var
        PostCode: Record "Post Code";
        "count": Integer;
    begin
        PostCode.DeleteAll();
        for count := 1 to 10 do begin
            PostCode.Init();
            PostCode.Code := Format(LibraryRandom.RandIntInRange(1000, 9999));
            PostCode.City := LibraryUtility.GenerateRandomCode(PostCode.FieldNo(City), DATABASE::"Post Code");
            PostCode.Insert();
        end;
    end;

    local procedure VerifyPostCode(NewPostCode: Text; NewCity: Text; NewCounty: Text)
    var
        PostCode: Record "Post Code";
    begin
        PostCode.Get(NewPostCode, NewCity);
        PostCode.TestField("Search City", UpperCase(NewCity));
        PostCode.TestField(County, NewCounty);
        PostCode.TestField("Country/Region Code", '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
        Assert.AreEqual(Format(ImportSuccessfulMsg), Message, '');
    end;
}

