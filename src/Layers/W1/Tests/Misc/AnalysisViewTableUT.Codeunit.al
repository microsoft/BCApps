codeunit 134066 "Analysis View Table-UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Analysis View] [UT]
    end;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        SameDimensionCodeError: Label 'This dimension is used in the following setup: Analysis View Card.';
        AreNotEqualError: Label 'The dimension code value is not equal to previous value.';
        DimensionCode: Option Code1,Code2,Code3,Code4;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithBlockedTrueForDimesion2Code()
    var
        AnalysisView: Record "Analysis View";
    begin
        // Exercise: Create Analysis View.
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate(Blocked, true); // As  Blocked True.
        AnalysisView.Modify(true);
        asserterror AnalysisView.Validate("Dimension 2 Code", CreateDimension());

        // Verify: Verify Error Message.
        Assert.ExpectedTestFieldError(AnalysisView.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithBlockedTrueForDimesion3Code()
    var
        AnalysisView: Record "Analysis View";
    begin
        // Exercise: Create Analysis View.
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate(Blocked, true); // As  Blocked True.
        AnalysisView.Modify(true);
        asserterror AnalysisView.Validate("Dimension 3 Code", CreateDimension());

        // Verify: Verify Error Message.
        Assert.ExpectedTestFieldError(AnalysisView.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithBlockedTrueForDimesion4Code()
    var
        AnalysisView: Record "Analysis View";
    begin
        // Exercise: Create Analysis View.
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate(Blocked, true); // As  Blocked True.
        AnalysisView.Modify(true);
        asserterror AnalysisView.Validate("Dimension 4 Code", CreateDimension());

        // Verify: Verify Error Message.
        Assert.ExpectedTestFieldError(AnalysisView.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithNewDimension2CodeWithVerifyErrorMessage()
    var
        AnalysisView: Record "Analysis View";
    begin
        // Exercise: Create Analysis View And Update the Dimension 2 Code.
        LibraryERM.CreateAnalysisView(AnalysisView);
        UpdateDimensionsOnAnalysisView(AnalysisView, DimensionCode::Code2);
        UpdateDimensionsOnAnalysisView(AnalysisView, DimensionCode::Code4);
        asserterror AnalysisView.Validate("Dimension 2 Code", AnalysisView."Dimension 4 Code");

        // Verify: Verify Error Message.
        Assert.ExpectedError(SameDimensionCodeError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithNewDimension3CodeWithVerifyErrorMessage()
    var
        AnalysisView: Record "Analysis View";
    begin
        // Exercise: Create Analysis View And Update the Dimension 3 Code.
        LibraryERM.CreateAnalysisView(AnalysisView);
        UpdateDimensionsOnAnalysisView(AnalysisView, DimensionCode::Code3);
        UpdateDimensionsOnAnalysisView(AnalysisView, DimensionCode::Code2);
        asserterror AnalysisView.Validate("Dimension 3 Code", AnalysisView."Dimension 2 Code");

        // Verify: Verify Error Message.
        Assert.ExpectedError(SameDimensionCodeError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithNewDimension4CodeWithVerifyErrorMessage()
    var
        AnalysisView: Record "Analysis View";
    begin
        // Exercise: Create Analysis View And Update the Dimension 4 Code.
        LibraryERM.CreateAnalysisView(AnalysisView);
        UpdateDimensionsOnAnalysisView(AnalysisView, DimensionCode::Code4);
        UpdateDimensionsOnAnalysisView(AnalysisView, DimensionCode::Code3);
        asserterror AnalysisView.Validate("Dimension 4 Code", AnalysisView."Dimension 3 Code");

        // Verify: Verify Error Message.
        Assert.ExpectedError(SameDimensionCodeError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithNewDimension2CodeWithVerifyModification()
    var
        AnalysisView: Record "Analysis View";
        Dimension2Code: Code[20];
    begin
        // Exercise: Create Analysis View And Update the Dimension 2 Code.
        LibraryERM.CreateAnalysisView(AnalysisView);
        UpdateDimensionsOnAnalysisView(AnalysisView, DimensionCode::Code2);
        Dimension2Code := AnalysisView."Dimension 2 Code";
        AnalysisView.Validate("Dimension 2 Code", CreateDimension());
        AnalysisView.Modify(true);

        // Verify: Verifying Modified Analysis View Dimension 2 code.
        Assert.AreNotEqual(AnalysisView."Dimension 2 Code", Dimension2Code, AreNotEqualError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithNewDimension3CodeWithVerifyModification()
    var
        AnalysisView: Record "Analysis View";
        Dimension3Code: Code[20];
    begin
        // Exercise: Create Analysis View And Update the Dimension 3 Code.
        LibraryERM.CreateAnalysisView(AnalysisView);
        UpdateDimensionsOnAnalysisView(AnalysisView, DimensionCode::Code3);
        Dimension3Code := AnalysisView."Dimension 3 Code";
        AnalysisView.Validate("Dimension 3 Code", CreateDimension());
        AnalysisView.Modify(true);

        // Verify: Verifying Modified Analysis View Dimension 3 code.
        Assert.AreNotEqual(AnalysisView."Dimension 3 Code", Dimension3Code, AreNotEqualError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithNewDimension4CodeWithVerifyModification()
    var
        AnalysisView: Record "Analysis View";
        Dimension4Code: Code[20];
    begin
        // Exercise: Create Analysis View And Update the Dimension 4 Code.
        LibraryERM.CreateAnalysisView(AnalysisView);
        UpdateDimensionsOnAnalysisView(AnalysisView, DimensionCode::Code4);
        Dimension4Code := AnalysisView."Dimension 4 Code";
        AnalysisView.Validate("Dimension 4 Code", CreateDimension());
        AnalysisView.Modify(true);

        // Verify: Verify Modified Analysis View Dimension 4 code.
        Assert.AreNotEqual(AnalysisView."Dimension 4 Code", Dimension4Code, AreNotEqualError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AnalysisViewEntryToGLEntriesSameGLEntry()
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        TempGLEntry: Record "G/L Entry" temporary;
        GLEntry: Record "G/L Entry";
        AnalysisViewEntryToGLEntries: Codeunit AnalysisViewEntryToGLEntries;
    begin
        LibraryERM.CreateAnalysisView(AnalysisView);

        GLEntry.FindLast();
        AnalysisViewEntry."Analysis View Code" := AnalysisView.Code;
        AnalysisViewEntry."Account No." := GLEntry."G/L Account No.";
        AnalysisViewEntry."Posting Date" := GLEntry."Posting Date";
        AnalysisViewEntry.Insert();

        AnalysisView."Last Entry No." := GLEntry."Entry No.";
        AnalysisView.Modify(true);

        // Exercise
        AnalysisViewEntryToGLEntries.GetGLEntries(AnalysisViewEntry, TempGLEntry);
        AnalysisViewEntryToGLEntries.GetGLEntries(AnalysisViewEntry, TempGLEntry);
    end;

    local procedure CreateDimension(): Code[20]
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        exit(Dimension.Code);
    end;

    local procedure UpdateDimensionsOnAnalysisView(var AnalysisView: Record "Analysis View"; DimensionCode: Option Code1,Code2,Code3,Code4)
    begin
        case DimensionCode of
            DimensionCode::Code1:
                AnalysisView.Validate("Dimension 1 Code", CreateDimension());
            DimensionCode::Code2:
                AnalysisView.Validate("Dimension 2 Code", CreateDimension());
            DimensionCode::Code3:
                AnalysisView.Validate("Dimension 3 Code", CreateDimension());
            DimensionCode::Code4:
                AnalysisView.Validate("Dimension 4 Code", CreateDimension());
        end;
        AnalysisView.Modify(true);
    end;
}

