codeunit 134482 "Test Change Shortcut Dimension"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Shortcut]
    end;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestClearAllShortCutDims()
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Exercise
        ClearShortCutDims();

        // Validate
        DimensionValue.SetRange("Global Dimension No.", 3, 8);
        Assert.AreEqual(0, DimensionValue.Count, '');

        DimensionSetEntry.SetRange("Global Dimension No.", 3, 8);
        Assert.AreEqual(0, DimensionSetEntry.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssignShortCutDims()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        DimNo: Integer;
    begin
        // Exercise
        ClearShortCutDims();
        DimNo := 2;
        GeneralLedgerSetup.Get();
        if Dimension.FindSet() then
            repeat
                if not (Dimension.Code in [GeneralLedgerSetup."Global Dimension 1 Code", GeneralLedgerSetup."Global Dimension 2 Code"]) then begin
                    DimNo += 1;
                    case DimNo of
                        3:
                            GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
                        4:
                            GeneralLedgerSetup.Validate("Shortcut Dimension 4 Code", Dimension.Code);
                        5:
                            GeneralLedgerSetup.Validate("Shortcut Dimension 5 Code", Dimension.Code);
                        6:
                            GeneralLedgerSetup.Validate("Shortcut Dimension 6 Code", Dimension.Code);
                        7:
                            GeneralLedgerSetup.Validate("Shortcut Dimension 7 Code", Dimension.Code);
                        8:
                            GeneralLedgerSetup.Validate("Shortcut Dimension 8 Code", Dimension.Code);
                    end;
                    VerifyDimValueGlobalDimNo(Dimension.Code, DimNo);
                end;
            until (DimNo = 8) or (Dimension.Next() = 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetShortcutDimCached()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension1: Record Dimension;
        Dimension2: Record Dimension;
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DimensionManagement: Codeunit DimensionManagement;
        DimValueCode1: array[8] of Code[20];
        DimValueCode2: array[8] of Code[20];
        DimSetID1: Integer;
        DimSetID2: Integer;
    begin
        // Init
        ClearShortCutDims();
        LibraryDimension.CreateDimension(Dimension1);
        LibraryDimension.CreateDimensionValue(DimensionValue1, Dimension1.Code);
        DimSetID1 := LibraryDimension.CreateDimSet(DimSetID1, DimensionValue1."Dimension Code", DimensionValue1.Code);
        LibraryDimension.CreateDimension(Dimension2);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension2.Code);
        DimSetID2 := LibraryDimension.CreateDimSet(DimSetID2, DimensionValue2."Dimension Code", DimensionValue2.Code);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension1.Code);
        GeneralLedgerSetup.Modify();

        // Execute
        DimensionManagement.GetShortcutDimensions(DimSetID1, DimValueCode1);
        DimensionManagement.GetShortcutDimensions(DimSetID2, DimValueCode2);
        Assert.AreEqual('', DimValueCode2[4], '');
        GeneralLedgerSetup.Validate("Shortcut Dimension 4 Code", Dimension2.Code);
        GeneralLedgerSetup.Modify();
        Sleep(60500); // wait for timeout
        DimensionManagement.GetShortcutDimensions(DimSetID2, DimValueCode2);

        // Validate
        Assert.AreEqual(DimensionValue1.Code, DimValueCode1[3], '');
        Assert.AreEqual('', DimValueCode1[4], '');
        Assert.AreEqual(DimensionValue2.Code, DimValueCode2[4], '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroGlobalDimNoOnInsertNewDimValue()
    begin
        // [SCENARIO 376608] "Dimension Value"."Global Dimension No." = 0 OnInsert new Dim Value into Dimension which is not in list of GLSetup Dimension codes
        GlobalDimNoOnInsertNewShortCutDimValue(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimNoOnInsertNewShortCutDim1Value()
    begin
        // [SCENARIO 376608] "Dimension Value"."Global Dimension No." = 1 OnInsert new Dim Value into Dimension.Code = GLSetup."Global Dimension 1 Code"
        GlobalDimNoOnInsertNewShortCutDimValue(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimNoOnInsertNewShortCutDim2Value()
    begin
        // [SCENARIO 376608] "Dimension Value"."Global Dimension No." = 2 OnInsert new Dim Value into Dimension.Code = GLSetup."Global Dimension 2 Code"
        GlobalDimNoOnInsertNewShortCutDimValue(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimNoOnInsertNewShortCutDim3Value()
    begin
        // [SCENARIO 376608] "Dimension Value"."Global Dimension No." = 3 OnInsert new Dim Value into Dimension.Code = GLSetup."Shortcut Dimension 3 Code"
        GlobalDimNoOnInsertNewShortCutDimValue(3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimNoOnInsertNewShortCutDim4Value()
    begin
        // [SCENARIO 376608] "Dimension Value"."Global Dimension No." = 4 OnInsert new Dim Value into Dimension.Code = GLSetup."Shortcut Dimension 4 Code"
        GlobalDimNoOnInsertNewShortCutDimValue(4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimNoOnInsertNewShortCutDim5Value()
    begin
        // [SCENARIO 376608] "Dimension Value"."Global Dimension No." = 5 OnInsert new Dim Value into Dimension.Code = GLSetup."Shortcut Dimension 5 Code"
        GlobalDimNoOnInsertNewShortCutDimValue(5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimNoOnInsertNewShortCutDim6Value()
    begin
        // [SCENARIO 376608] "Dimension Value"."Global Dimension No." = 6 OnInsert new Dim Value into Dimension.Code = GLSetup."Shortcut Dimension 6 Code"
        GlobalDimNoOnInsertNewShortCutDimValue(6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimNoOnInsertNewShortCutDim7Value()
    begin
        // [SCENARIO 376608] "Dimension Value"."Global Dimension No." = 7 OnInsert new Dim Value into Dimension.Code = GLSetup."Shortcut Dimension 7 Code"
        GlobalDimNoOnInsertNewShortCutDimValue(7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimNoOnInsertNewShortCutDim8Value()
    begin
        // [SCENARIO 376608] "Dimension Value"."Global Dimension No." = 8 OnInsert new Dim Value into Dimension.Code = GLSetup."Shortcut Dimension 8 Code"
        GlobalDimNoOnInsertNewShortCutDimValue(8);
    end;

    local procedure GlobalDimNoOnInsertNewShortCutDimValue(ShortCutDimNo: Integer)
    var
        DimensionValue: Record "Dimension Value";
    begin
        CreateShortCutDimValue(DimensionValue, ShortCutDimNo);
        Assert.AreEqual(ShortCutDimNo, DimensionValue."Global Dimension No.", DimensionValue.FieldCaption("Global Dimension No."));
    end;

    local procedure CreateShortCutDimValue(var DimensionValue: Record "Dimension Value"; ShortCutDimNo: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);

        if ShortCutDimNo <> 0 then begin
            GeneralLedgerSetup.Get();
            case ShortCutDimNo of
                1:
                    GeneralLedgerSetup.Validate("Global Dimension 1 Code", Dimension.Code);
                2:
                    GeneralLedgerSetup.Validate("Global Dimension 2 Code", Dimension.Code);
                3:
                    GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
                4:
                    GeneralLedgerSetup.Validate("Shortcut Dimension 4 Code", Dimension.Code);
                5:
                    GeneralLedgerSetup.Validate("Shortcut Dimension 5 Code", Dimension.Code);
                6:
                    GeneralLedgerSetup.Validate("Shortcut Dimension 6 Code", Dimension.Code);
                7:
                    GeneralLedgerSetup.Validate("Shortcut Dimension 7 Code", Dimension.Code);
                8:
                    GeneralLedgerSetup.Validate("Shortcut Dimension 8 Code", Dimension.Code);
            end;
            GeneralLedgerSetup.Modify();
        end;

        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure ClearShortCutDims()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", '');
        GeneralLedgerSetup.Validate("Shortcut Dimension 4 Code", '');
        GeneralLedgerSetup.Validate("Shortcut Dimension 5 Code", '');
        GeneralLedgerSetup.Validate("Shortcut Dimension 6 Code", '');
        GeneralLedgerSetup.Validate("Shortcut Dimension 7 Code", '');
        GeneralLedgerSetup.Validate("Shortcut Dimension 8 Code", '');
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyDimValueGlobalDimNo(DimCode: Code[20]; DimNo: Integer)
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        if DimCode = '' then
            exit;
        DimensionValue.SetRange("Dimension Code", DimCode);
        if DimensionValue.FindSet() then
            repeat
                Assert.AreEqual(DimNo, DimensionValue."Global Dimension No.", '');
            until DimensionValue.Next() = 0;

        DimensionSetEntry.SetRange("Dimension Code", DimCode);
        if DimensionSetEntry.FindSet() then
            repeat
                Assert.AreEqual(DimNo, DimensionSetEntry."Global Dimension No.", '');
            until DimensionSetEntry.Next() = 0;
    end;
}

