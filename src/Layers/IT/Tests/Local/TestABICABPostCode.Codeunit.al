codeunit 144107 "Test ABI/CAB Post Code"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    [Scope('OnPrem')]
    procedure PostCodeNotExistent()
    var
        ABICABCodes: Record "ABI/CAB Codes";
    begin
        // Setup
        CreateAbiCabCode(ABICABCodes);

        // Exercise
        ABICABCodes.Validate("Post Code", LibraryUtility.GenerateRandomCode(ABICABCodes.FieldNo("Post Code"), DATABASE::"ABI/CAB Codes"));

        // Validate
        ABICABCodes.TestField(City, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CityNotExistent()
    var
        ABICABCodes: Record "ABI/CAB Codes";
    begin
        // Setup
        CreateAbiCabCode(ABICABCodes);

        // Exercise
        ABICABCodes.Validate(City, LibraryUtility.GenerateRandomText(30));

        // Validate
        ABICABCodes.TestField("Post Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistentPostCode()
    var
        ABICABCodes: Record "ABI/CAB Codes";
        PostCode: Record "Post Code";
    begin
        // Setup
        CreateAbiCabCode(ABICABCodes);
        LibraryERM.CreatePostCode(PostCode);

        // Exercise
        ABICABCodes.Validate("Post Code", PostCode.Code);

        // Validate
        ABICABCodes.TestField(City, PostCode.City);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistentCity()
    var
        ABICABCodes: Record "ABI/CAB Codes";
        PostCode: Record "Post Code";
    begin
        // Setup
        CreateAbiCabCode(ABICABCodes);
        LibraryERM.CreatePostCode(PostCode);

        // Exercise
        ABICABCodes.Validate(City, PostCode.City);

        // Validate
        ABICABCodes.TestField("Post Code", PostCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeExistentPostCode()
    var
        ABICABCodes: Record "ABI/CAB Codes";
        PostCode: Record "Post Code";
    begin
        // Setup
        CreateAbiCabCode(ABICABCodes);
        LibraryERM.CreatePostCode(PostCode);

        // Pre-Exercise
        ABICABCodes.Validate("Post Code", PostCode.Code);

        // Pre-Validate
        ABICABCodes.TestField(City, PostCode.City);

        // Exercise
        ABICABCodes.Validate("Post Code", '');

        // Validate
        ABICABCodes.TestField(City, PostCode.City);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeExistentCity()
    var
        ABICABCodes: Record "ABI/CAB Codes";
        PostCode: Record "Post Code";
    begin
        // Setup
        CreateAbiCabCode(ABICABCodes);
        LibraryERM.CreatePostCode(PostCode);

        // Pre-Exercise
        ABICABCodes.Validate(City, PostCode.City);

        // Pre-Validate
        ABICABCodes.TestField("Post Code", PostCode.Code);

        // Exercise
        ABICABCodes.Validate(City, '');

        // Validate
        ABICABCodes.TestField("Post Code", PostCode.Code);
    end;

    local procedure CreateAbiCabCode(var ABICABCodes: Record "ABI/CAB Codes")
    begin
        ABICABCodes.Init();
        ABICABCodes.Validate(ABI, LibraryUtility.GenerateRandomCode(ABICABCodes.FieldNo(ABI), DATABASE::"ABI/CAB Codes"));
        ABICABCodes.Validate(CAB, LibraryUtility.GenerateRandomCode(ABICABCodes.FieldNo(CAB), DATABASE::"ABI/CAB Codes"));
        ABICABCodes.Insert(true);
    end;
}

