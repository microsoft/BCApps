codeunit 134487 "Default Dimension"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Default Dimension]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        NoValidateErr: Label 'The field No. of table Default Dimension contains a value (%1) that cannot be found in the related table (%2)';
        LibraryRapidStart: Codeunit "Library - Rapid Start";

    [Test]
    [HandlerFunctions('DefaultDimensionsMPH')]
    [Scope('OnPrem')]
    procedure T001_SetDefaultDimForMockMasterWithDimsTable()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        TableWithDefaultDim: Record "Table With Default Dim";
        MockMasterWithDimsCard: TestPage "Mock Master With Dims Card";
    begin
        // [FEATURE] [UI] [UT]
        // [GIVEN] Master table record 'A', where are Global Dimension fields.
        TableWithDefaultDim."No." := LibraryUtility.GenerateGUID();
        TableWithDefaultDim.Insert();
        // [GIVEN] Run 'Dimension - Single' action on the card page
        MockMasterWithDimsCard.OpenView();
        MockMasterWithDimsCard.Dimensions.Invoke();

        // [WHEN] Define the Default Dimension 'Department'-'ADM' for 'A' in the page
        DimensionValue.Get(LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText()); // by DefaultDimensionsMPH

        // [THEN] Default Dimension 'Department'-'ADM' for 'A' does exist
        DefaultDimension.Get(
          DATABASE::"Table With Default Dim", TableWithDefaultDim."No.", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMPH')]
    [Scope('OnPrem')]
    procedure T002_SetDefaultDimForMockMasterWithOutDimsTable()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        MockMasterTable: Record "Mock Master Table";
        DefaultDimensionCodeunit: Codeunit "Default Dimension";
        MockMasterWithoutDimsCard: TestPage "Mock Master Without Dims Card";
    begin
        // [FEATURE] [UI] [UT]
        // [GIVEN] Master table record 'A', where are no Global Dimension fields.
        MockMasterTable."No." := LibraryUtility.GenerateGUID();
        MockMasterTable.Insert();
        // [GIVEN] Subscribed to COD408.OnAfterSetupObjectNoList to add table to the allowed table ID list
        BindSubscription(DefaultDimensionCodeunit);
        // [GIVEN] Run 'Dimension - Single' action on the card page
        MockMasterWithoutDimsCard.OpenView();
        MockMasterWithoutDimsCard.Dimensions.Invoke();

        // [WHEN] Define the Default Dimension 'Department'-'ADM' for 'A' in the page
        DimensionValue.Get(LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText()); // by DefaultDimensionsMPH

        // [THEN] Default Dimension 'Department'-'ADM' for 'A' does exist
        DefaultDimension.Get(
          DATABASE::"Mock Master Table", MockMasterTable."No.", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T009_DefaultDimObjListIncludesOneFieldPKeyTables()
    var
        TempAllObjWithCaption: Record AllObjWithCaption temporary;
        TableMetadata: Record "Table Metadata";
        DimensionManagement: Codeunit DimensionManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] All tables returned by COD408.DefaultDimObjectNoList() have captions, are not obsolete, and Primary Key of one field.
        DimensionManagement.DefaultDimObjectNoList(TempAllObjWithCaption);
        if TempAllObjWithCaption.FindSet() then
            repeat
                TableMetadata.Get(TempAllObjWithCaption."Object ID");
                if TableMetadata.ObsoleteState = TableMetadata.ObsoleteState::Removed then
                    TableMetadata.FieldError(ObsoleteState);
                TempAllObjWithCaption.TestField("Object Caption");
                Assert.IsTrue(PKContainsOneField(TempAllObjWithCaption."Object ID"), 'PK contains not one field:' + Format(TempAllObjWithCaption."Object ID"));
            until TempAllObjWithCaption.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T010_DefaultDimForAllAllowedTables()
    var
        TempAllObjWithCaption: Record AllObjWithCaption temporary;
        TableMetadata: Record "Table Metadata";
        DimensionManagement: Codeunit DimensionManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] All tables returned by COD408.DefaultDimObjectNoList support Rename and Delete.
        DimensionManagement.DefaultDimObjectNoList(TempAllObjWithCaption);
        TempAllObjWithCaption.SetFilter("Object ID", '<>%1', DATABASE::"Table With Default Dim");
        if TempAllObjWithCaption.FindSet() then
            repeat
                TableMetadata.Get(TempAllObjWithCaption."Object ID");
                if TableMetadata.ObsoleteState = TableMetadata.ObsoleteState::No then
                    ValidateNotExistingNo(TempAllObjWithCaption."Object ID", RenameMasterRecord(TempAllObjWithCaption."Object ID"));
            until TempAllObjWithCaption.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionLinesAreNotAddedAfterCreatingConfigurationLine()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        DefaultDimension: Record "Default Dimension";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        TableNo: Record "Integer" temporary;
    begin
        // [FEATURE] [Rapid Start] [Global Dimension]
        // [SCENARIO 330950] Create Configuration Template Header and Configuration Template Line for 19 different tables.
        // [GIVEN] Array of Table, that creates Default Dimension lines, was created.
        LibraryDimension.GetTableNosWithGlobalDimensionCode(TableNo);

        TableNo.FindSet();
        repeat
            // [GIVEN] Configuration Header was created.
            LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
            ConfigTemplateHeader.Validate("Table ID", TableNo.Number);
            ConfigTemplateHeader.Modify(true);

            // [GIVEN] Dimension value for Global Dimension 1 Code was extracted.
            GeneralLedgerSetup.Get();
            DimensionValue.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 1 Code");
            DimensionValue.FindFirst();

            // [WHEN] Configuration Template Line is created.
            LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
            ConfigTemplateLine.Validate("Field ID", GetFieldNoGlobalDimension1ByTableNo(TableNo.Number));
            ConfigTemplateLine.Validate("Default Value", DimensionValue.Code);
            ConfigTemplateLine.Modify(true);

            // [THEN] The lines was not added to Default Dimension.
            DefaultDimension.SetRange("No.", '');
            Assert.RecordIsEmpty(DefaultDimension);
        until TableNo.Next() = 0;
    end;

    local procedure RenameMasterRecord(TableID: Integer) PK: Code[20]
    var
        DefaultDimension: array[2] of Record "Default Dimension";
        NewPK: Code[20];
    begin
        // [GIVEN] SalespersonPurchaser 'A' with Default Dimensions 'Department' and 'Project'
        PK := NewRecord(TableID);
        CreateDefaultDimension(TableID, PK, DefaultDimension[1]);
        CreateDefaultDimension(TableID, PK, DefaultDimension[2]);
        // [WHEN] rename 'A' to 'B'
        NewPK := RenameRecord(TableID, PK);
        // [THEN] Record 'B' has Default Dimensions 'Department' and 'Project'
        VerifyRenamedDefaultDimensions(DefaultDimension, TableID, PK, NewPK);
    end;

    local procedure ValidateNotExistingNo(TableID: Integer; PK: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [GIVEN] Record 'X' does not exist
        // [WHEN] Default Dimension, where validate "No." as 'X'
        asserterror CreateDefaultDimension(TableID, PK, DefaultDimension);
        // [THEN] Error message 'Value X cannot be found in the related table'
        Assert.ExpectedError(StrSubstNo(NoValidateErr, PK, GetTableCaption(TableID)));
    end;

    local procedure CreateDefaultDimension(TableNo: Integer; PK: Code[20]; var DefaultDimension: Record "Default Dimension")
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableNo, PK, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure GetTableCaption(TableID: Integer) TableCaption: Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        TableCaption := RecRef.Caption;
        RecRef.Close();
    end;

    local procedure NewRecord(TableID: Integer) PK: Code[20]
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        RecRef: RecordRef;
    begin
        PK := LibraryUtility.GenerateGUID();
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        FieldRef.Value := PK;
        Assert.IsTrue(RecRef.Insert(), 'INSERT has failed');
        RecRef.Close();
    end;

    local procedure RenameRecord(TableID: Integer; PK: Code[20]) NewPK: Code[20]
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        RecRef: RecordRef;
    begin
        NewPK := LibraryUtility.GenerateGUID();
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        FieldRef.SetRange(PK);
        RecRef.FindFirst();
        Assert.IsTrue(RecRef.Rename(NewPK), 'RENAME has failed');
        RecRef.Close();
    end;

    local procedure PKContainsOneField(TableID: Integer) Result: Boolean
    var
        KeyRef: KeyRef;
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        Result := KeyRef.FieldCount = 1;
        RecRef.Close();
    end;

    local procedure VerifyRenamedDefaultDimensions(DefaultDimension: array[2] of Record "Default Dimension"; TableID: Integer; PK: Code[20]; NewPK: Code[20])
    begin
        Assert.IsTrue(DefaultDimension[1].Get(TableID, NewPK, DefaultDimension[1]."Dimension Code"), 'New#1 ' + Format(TableID));
        Assert.IsFalse(DefaultDimension[1].Get(TableID, PK, DefaultDimension[1]."Dimension Code"), 'Old#1 ' + Format(TableID));
        Assert.IsTrue(DefaultDimension[2].Get(TableID, NewPK, DefaultDimension[2]."Dimension Code"), 'New#2 ' + Format(TableID));
        Assert.IsFalse(DefaultDimension[2].Get(TableID, PK, DefaultDimension[2]."Dimension Code"), 'Old#2 ' + Format(TableID));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DefaultDimensionsMPH(var DefaultDimensionsPage: TestPage "Default Dimensions")
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        DefaultDimensionsPage.New();
        DefaultDimensionsPage."Dimension Code".SetValue(DimensionValue."Dimension Code");
        DefaultDimensionsPage."Dimension Value Code".SetValue(DimensionValue.Code);
        DefaultDimensionsPage.OK().Invoke();
    end;

    local procedure GetFieldNoGlobalDimension1ByTableNo(TableNo: Integer): Integer
    var
        "Field": Record "Field";
    begin
        Field.Reset();
        Field.SetRange(TableNo, TableNo);
        Field.SetRange(FieldName, 'Global Dimension 1 Code');
        Field.FindFirst();
        exit(Field."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"DimensionManagement", 'OnAfterSetupObjectNoList', '', false, false)]
    local procedure OnAfterSetupObjectNoListHandler(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.InsertObject(TempAllObjWithCaption, DATABASE::"Mock Master Table");
    end;
}

