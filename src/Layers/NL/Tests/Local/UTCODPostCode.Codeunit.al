codeunit 144021 "UT COD Post Code"
{
    // Test for feature Post Code.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUTUtility: Codeunit "Library UT Utility";
        ValueMustEqualMsg: Label 'Value must be Equal.';
        PostCodeMgt: Codeunit "Post Code Management";
        StreetNameErr: Label 'Wrong StreetName';
        HouseNoErr: Label 'Wrong HouseNo';
        AdditionHouseNoErr: Label 'Wrong AdditionHouseNo';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindStreetNameFromAddressTypeBlankPostCodeManagement()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate FindStreetNameFromAddress function of CodeUnit ID - 11401 Post Code Management.
        FindStreetNameFromAddressWithoutHouseNoPostCodeManagement(PostCodeRange.Type);  // Default value is blank.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindStreetNameFromAddressTypeHouseBoatPostCodeManagement()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate FindStreetNameFromAddress function of CodeUnit ID - 11401 Post Code Management.
        FindStreetNameFromAddressWithoutHouseNoPostCodeManagement(PostCodeRange.Type::"House Boat");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindStreetNameFromAddressTypeHouseTrailerPostCodeManagement()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate FindStreetNameFromAddress function of CodeUnit ID - 11401 Post Code Management.
        FindStreetNameFromAddressWithoutHouseNoPostCodeManagement(PostCodeRange.Type::"House Trailer");
    end;

    local procedure FindStreetNameFromAddressWithoutHouseNoPostCodeManagement(Type: Option)
    var
        PostCodeRange: Record "Post Code Range";
        PostCode: Code[20];
        Address: Text[50];
        Address2: Text[50];
        City: Text[50];
        FaxNo: Text[30];
        PhoneNo: Text[30];
        CountryCode: Code[10];
    begin
        // Setup: Create Post Code Range.
        CreatePostCodeRange(PostCodeRange, Type, LibraryRandom.RandInt(10));  // Random value for From Number.
        Address := PostCodeRange."Post Code";

        // Exercise: Execute FindStreetNameFromAddress of CodeUnit Post Code Management.
        PostCodeMgt.FindStreetName(Address, Address2, PostCode, City, CountryCode, PhoneNo, FaxNo);  // Blank value for Country Code.

        // Verify: Verify Updated City and Post Code with expected City and Post Code.
        VerifyPostCodeAndCity(PostCodeRange."Post Code", PostCodeRange.City, PostCode, City);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindStreetNameFromAddressTypeOddPostCodeManagement()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate FindStreetNameFromAddress function of CodeUnit ID - 11401 Post Code Management.
        FindStreetNameFromAddressWithHouseNoCodeManagement(PostCodeRange.Type::Odd, 2 * LibraryRandom.RandInt(10) + 1);  // Random odd value for From Number.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindStreetNameFromAddressTypeEvenPostCodeManagement()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        // Purpose of the test is to validate FindStreetNameFromAddress function of CodeUnit ID - 11401 Post Code Management.
        FindStreetNameFromAddressWithHouseNoCodeManagement(PostCodeRange.Type::Even, 2 * LibraryRandom.RandInt(10));  // Random even value for From Number.
    end;

    local procedure FindStreetNameFromAddressWithHouseNoCodeManagement(Type: Option; FromNo: Integer)
    var
        PostCodeRange: Record "Post Code Range";
        PostCode: Code[20];
        Address: Text[50];
        Address2: Text[50];
        City: Text[50];
        FaxNo: Text[30];
        PhoneNo: Text[30];
        CountryCode: Code[10];
    begin
        // Create Post Code Range.
        CreatePostCodeRange(PostCodeRange, Type, FromNo);
        Address := PostCodeRange."Post Code" + Format(PostCodeRange."From No.");

        // Exercise: Execute FindStreetNameFromAddress of CodeUnit Post Code Management.
        PostCodeMgt.FindStreetName(Address, Address2, PostCode, City, CountryCode, PhoneNo, FaxNo);  // Blank value for Country Code.

        // Verify: Verify Updated City and Post Code with expected City and Post Code.
        VerifyPostCodeAndCity(PostCodeRange."Post Code", PostCodeRange.City, PostCode, City);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionHouseNo1()
    begin
        AdditionHouseNo('OneWordAddress', 'OneWordAddress', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionHouseNo2()
    begin
        AdditionHouseNo('Several Words Address', 'Several Words Address', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionHouseNo3()
    begin
        AdditionHouseNo('9th May Street', '9th May Street', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionHouseNo4()
    begin
        AdditionHouseNo('Some Street 5', 'Some Street', '5', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionHouseNo5()
    begin
        AdditionHouseNo('Some Street 5B', 'Some Street', '5', 'B');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionHouseNo6()
    begin
        AdditionHouseNo('9th of May 5\BC', '9th of May', '5', 'BC');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionHouseNo7()
    begin
        AdditionHouseNo('7th Street of 9th May 5-ABC', '7th Street of 9th May', '5', 'ABC');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionHouseNo8()
    begin
        AdditionHouseNo('71th Street of 9th May 52-A/BC', '71th Street of 9th May', '52', 'A/BC');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionHouseNo9()
    begin
        AdditionHouseNo('712th Street of 9th May 523-A-B-C', '712th Street of 9th May', '523', 'A-B-C');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionHouseNo10()
    begin
        AdditionHouseNo('7123th   Street   of       9th   May   5234-A/B/C', '7123th   Street   of       9th   May  ', '5234', 'A/B/C');
    end;

    local procedure AdditionHouseNo(Address: Text[50]; ExpStreetName: Text[50]; ExpHouseNo: Text[50]; ExpAdditionHouseNo: Text[50])
    var
        StreetName: Text[50];
        HouseNo: Text[50];
        AdditionHouseNo: Text[50];
    begin
        PostCodeMgt.ParseAddressAdditionHouseNo(StreetName, HouseNo, AdditionHouseNo, Address);
        Assert.AreEqual(ExpStreetName, StreetName, StreetNameErr);
        Assert.AreEqual(ExpHouseNo, HouseNo, HouseNoErr);
        Assert.AreEqual(ExpAdditionHouseNo, AdditionHouseNo, AdditionHouseNoErr);
    end;

    local procedure CreatePostCodeRange(var PostCodeRange: Record "Post Code Range"; Type: Option; FromNo: Integer)
    var
        PostCode: Record "Post Code";
    begin
        PostCode.Code := Format(LibraryRandom.RandIntInRange(1000, 9999)) + ' ' + 'ZZ';  // Code should contain 4 digit following space, two upper case alphabet.
        PostCode.City := LibraryUTUtility.GetNewCode();
        PostCode.Insert();

        PostCodeRange."Post Code" := PostCode.Code;
        PostCodeRange.City := PostCode.City;
        PostCodeRange.Type := Type;
        PostCodeRange."From No." := FromNo;
        PostCodeRange."To No." := PostCodeRange."From No." + LibraryRandom.RandInt(10);
        PostCodeRange."Street Name" := LibraryUTUtility.GetNewCode();
        PostCodeRange.Insert();
    end;

    local procedure VerifyPostCodeAndCity(ExpectedPostCode: Code[20]; ExpectedCity: Text[30]; ActualPostCode: Code[20]; ActualCity: Text[30])
    begin
        Assert.AreEqual(ExpectedPostCode, ActualPostCode, ValueMustEqualMsg);
        Assert.AreEqual(ExpectedCity, ActualCity, ValueMustEqualMsg);
    end;
}

