codeunit 135155 "Data Privacy Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Privacy]
    end;

    var
        DataPrivacyMgmt: Codeunit "Data Privacy Mgmt";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        InexistentTableId: Integer;
        InexistentFieldId: Integer;
        ExistentTableId: Integer;
        ExistentTableInexistentFieldId: Integer;
        BLOBTableId: Integer;
        BLOBFieldId: Integer;
        TextTableId: Integer;
        TextFieldId: Integer;
        IntegerTableId: Integer;
        IntegerFieldId: Integer;
        CodeTableId: Integer;
        CodeFieldId: Integer;
        OptionTableId: Integer;
        OptionFieldId: Integer;
        GUIDTableId: Integer;
        GUIDFieldId: Integer;
        PackageCodeKeepTxt: Label 'KEEP';
        PackageCodeTempTxt: Label 'TEMP';

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateConfigPackage()
    var
        ConfigPackage: Record "Config. Package";
        Language: Codeunit Language;
        PackageCode: Code[20];
        PackageName: Text[50];
    begin
        // [GIVEN] The Config. Package table is empty
        ConfigPackage.DeleteAll();

        // [GIVEN] A package code and a package name
        PackageCode := 'Code abc random';
        PackageName := 'Some package name';

        // [WHEN] Creating a new Config. Package with the given package code and name
        DataPrivacyMgmt.CreateConfigPackage(ConfigPackage, PackageCode, PackageName);

        // [THEN] The Config. Package table contains exactly one entry
        ConfigPackage.Reset();
        Assert.AreEqual(1, ConfigPackage.Count, 'There should be exactly one entry in the Config. Package table');

        if ConfigPackage.FindFirst() then begin
            // [THEN] The Config. Package's Code is PackageCode
            Assert.AreEqual(PackageCode, ConfigPackage.Code, 'The Code of the Config. Package is incorrect');

            // [THEN] The Config. Package's Package Name is PackageName
            Assert.AreEqual(PackageName, ConfigPackage."Package Name", 'The Package Name of the Config. Package is incorrect');

            // [THEN] The Config. Package's Language ID is the Application Language
            Assert.AreEqual(Language.GetDefaultApplicationLanguageId(), ConfigPackage."Language ID",
              'The Language ID of the Config. Package is incorrect');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePackageTable()
    var
        ConfigPackageTable: Record "Config. Package Table";
        DummyConfigPackage: Record "Config. Package";
        PackageCode: Code[20];
        TableId: Integer;
    begin
        // [GIVEN] The Config. Package Table table is empty
        ConfigPackageTable.DeleteAll();

        // [GIVEN] A PackageCode, TableId and a Config. Package record with the given PackageCode
        PackageCode := 'Code code';
        TableId := 27;
        DataPrivacyMgmt.CreateConfigPackage(DummyConfigPackage, PackageCode, 'random name');

        // [WHEN] Creating a new Config. Package Table with the given package code and table id
        DataPrivacyMgmt.CreatePackageTable(PackageCode, TableId);

        // [THEN] The Config. Package Table table contains exactly one entry
        ConfigPackageTable.Reset();
        Assert.AreEqual(1, ConfigPackageTable.Count, 'The Config. Package Table table should contain exactly one entry');

        ConfigPackageTable.FindFirst();
        // [THEN] The Config. Package Table's Package Code is PackageCode
        Assert.AreEqual(PackageCode, ConfigPackageTable."Package Code", 'The Package Code of the Config. Package Table is incorrect');
        // [THEN] The Config. Package Table's Table ID is TableId
        Assert.AreEqual(TableId, ConfigPackageTable."Table ID", 'The Table ID of the Config. Package Table is incorrect');
        // [THEN] ConfigPackageTable."Cross-Column Filter" = true (TFS 346990)
        Assert.AreEqual(true, ConfigPackageTable."Cross-Column Filter", '"Cross-Column Filter" is expected to be TRUE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePackageField()
    var
        ConfigPackageField: Record "Config. Package Field";
        DummyConfigPackage: Record "Config. Package";
        ProcessingOrder: Integer;
        ConfigPackageCode: Code[20];
        ConfigPackageFieldCreated: Boolean;
    begin
        InitTableAndFieldIds();

        // [GIVEN] The Config. Package Field is empty
        ConfigPackageField.DeleteAll();

        // [GIVEN] A ProcessingOrder, a ConfigPackageCode and a Config. Package with this code
        ProcessingOrder := 1;
        ConfigPackageCode := 'rAndOm cODe bLah';
        DataPrivacyMgmt.CreateConfigPackage(DummyConfigPackage, ConfigPackageCode, 'random name');

        // [WHEN] Trying to create a Config. Package Field with an inexistent table and field id
        ConfigPackageFieldCreated := DataPrivacyMgmt.CreatePackageField(
            ConfigPackageCode, InexistentTableId, InexistentFieldId, ProcessingOrder);

        // [THEN] The ConfigPackageFieldCreated variable should be false
        Assert.AreEqual(false, ConfigPackageFieldCreated, 'The 1st Config. Package Field should NOT have been created');

        // [THEN] The Config. Package Field table is empty
        ConfigPackageField.Reset();
        Assert.AreEqual(0, ConfigPackageField.Count, 'The Config. Package Field table should be empty');

        // [WHEN] Trying to create a Config. Package Field for an existent table, but inexistent field
        ConfigPackageFieldCreated := DataPrivacyMgmt.CreatePackageField(
            ConfigPackageCode, ExistentTableId, ExistentTableInexistentFieldId, ProcessingOrder);

        // [THEN] The ConfigPackageFieldCreated variable should be false
        Assert.AreEqual(false, ConfigPackageFieldCreated, 'The 2nd Config. Package Field should NOT have been created');

        // [THEN] The Config. Package Field table is empty
        ConfigPackageField.Reset();
        Assert.AreEqual(0, ConfigPackageField.Count, 'The Config. Package Field table should be empty');

        // [WHEN] Trying to create a Config. Package Field for an existent table and field id, 
        // that correspond to a BLOB field
        ConfigPackageFieldCreated := DataPrivacyMgmt.CreatePackageField(
            ConfigPackageCode, BLOBTableId, BLOBFieldId, ProcessingOrder);

        // [THEN] The ConfigPackageFieldCreated variable should be false
        Assert.AreEqual(false, ConfigPackageFieldCreated, 'The 3rd Config. Package Field should NOT have been created');

        // [THEN] The Config. Package Field table is empty
        ConfigPackageField.Reset();
        Assert.AreEqual(0, ConfigPackageField.Count, 'The Config. Package Field table should be empty');

        // [WHEN] Trying to create a Config. Package Field for an existent table and field id, 
        // that correspond to a GUID field
        ConfigPackageFieldCreated := DataPrivacyMgmt.CreatePackageField(
            ConfigPackageCode, GUIDTableId, GUIDFieldId, ProcessingOrder);

        // [THEN] The ConfigPackageFieldCreated variable should be false
        Assert.AreEqual(false, ConfigPackageFieldCreated, 'The 4th Config. Package Field should NOT have been created');

        // [THEN] The Config. Package Field table is empty
        ConfigPackageField.Reset();
        Assert.AreEqual(0, ConfigPackageField.Count, 'The Config. Package Field table should be empty');

        // [WHEN] Trying to create a Config. Package Field for an existent table and field id, 
        // that correspond to a Text field
        ConfigPackageFieldCreated := DataPrivacyMgmt.CreatePackageField(
            ConfigPackageCode, TextTableId, TextFieldId, ProcessingOrder);

        // [THEN] The ConfigPackageFieldCreated variable should be true
        Assert.AreEqual(true, ConfigPackageFieldCreated, 'The 5th Config. Package Field should have been created');

        // [THEN] The Config. Package Field table should have exactly one entry
        ConfigPackageField.Reset();
        Assert.AreEqual(1, ConfigPackageField.Count, 'The Config. Package Field table should contain exactly one entry');

        // [THEN] The Config. Package Field entry's fields are properly set
        if ConfigPackageField.FindFirst() then begin
            Assert.AreEqual(TextTableId, ConfigPackageField."Table ID", 'The Table ID of the Config. Package Field is incorrect');
            Assert.AreEqual(TextFieldId, ConfigPackageField."Field ID", 'The Field ID of the Config. Package Field is incorrect');
            Assert.AreEqual(ProcessingOrder, ConfigPackageField."Processing Order",
              'The Processing Order of the Config. Package Field is incorrect');
            Assert.AreEqual(ConfigPackageCode, ConfigPackageField."Package Code",
              'The Package Code of the Config. Package Field is incorrect');
            Assert.AreEqual(true, ConfigPackageField."Validate Field",
              'The Validate Field of the Config. Package Field is incorrect');
            Assert.AreEqual(true, ConfigPackageField."Include Field",
              'The Include Field of the Config. Package Field is incorrect');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePackageFilter()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackage: Record "Config. Package";
        FieldValue: Text[250];
        ConfigPackageCode: Code[20];
        ConfigPackageFilterCreated: Boolean;
    begin
        InitTableAndFieldIds();

        // [GIVEN] The Config. Package Filter and Config. Package tables are empty
        ConfigPackageFilter.DeleteAll();
        ConfigPackage.DeleteAll();

        // [GIVEN] A random ConfigPackageCode and a field value
        ConfigPackageCode := 'blah blah code';
        FieldValue := 'value';

        // [WHEN] Trying to create a Config. Package Filter for an existent table and field id, 
        // corresponding to a Text field, but having no Config. Package whose Code is ConfigPackageCode
        ConfigPackageFilterCreated := DataPrivacyMgmt.CreatePackageFilter(
            ConfigPackageCode, TextTableId, TextFieldId, FieldValue);

        // [THEN] The ConfigPackageFilterCreated variable should be false
        Assert.AreEqual(false, ConfigPackageFilterCreated, 'The 1st Config. Package Filter should NOT have been created');

        // [THEN] The Config. Package Filter table is empty
        ConfigPackageFilter.Reset();
        Assert.AreEqual(0, ConfigPackageFilter.Count, 'The Config. Package Filter table should be empty');

        // [GIVEN] A Config. Package with the Code ConfigPackageCode
        DataPrivacyMgmt.CreateConfigPackage(ConfigPackage, ConfigPackageCode, 'name');

        // [WHEN] Trying to create a Config. Package Filter
        ConfigPackageFilterCreated := DataPrivacyMgmt.CreatePackageFilter(
            ConfigPackageCode, TextTableId, TextFieldId, FieldValue);

        // [THEN] The ConfigPackageFilterCreated variable should be true
        Assert.AreEqual(true, ConfigPackageFilterCreated, 'The 2nd Config. Package Filter should have been created');

        // [THEN] The Config. Package Filter table should have exactly one entry
        ConfigPackageFilter.Reset();
        Assert.AreEqual(1, ConfigPackageFilter.Count, 'The Config. Package Filter table should contain one entry');

        // [THEN] The Config. Package Filter entry's fields are properly set
        if ConfigPackageFilter.FindFirst() then begin
            Assert.AreEqual(TextTableId, ConfigPackageFilter."Table ID", 'The Table ID of the Config. Package Filter is incorrect');
            Assert.AreEqual(TextFieldId, ConfigPackageFilter."Field ID", 'The Field ID of the Config. Package Filter is incorrect');
            Assert.AreEqual(ConfigPackageCode, ConfigPackageFilter."Package Code",
              'The Package Code of the Config. Package Filter is incorrect');
            Assert.AreEqual(Format(FieldValue), ConfigPackageFilter."Field Filter",
              'The Field Filter of the Config. Package Filter is incorrect');
        end;

        // [GIVEN] The Config. Package Filter table is empty
        ConfigPackageFilter.DeleteAll();

        // [WHEN] Trying to create a Config. Package Filter for an inexistent table and field id
        ConfigPackageFilterCreated := DataPrivacyMgmt.CreatePackageFilter(
            ConfigPackageCode, InexistentTableId, InexistentFieldId, FieldValue);

        // [THEN] The ConfigPackageFilterCreated variable should be false
        Assert.AreEqual(false, ConfigPackageFilterCreated, 'The 3rd Config. Package Filter should NOT have been created');

        // [THEN] The Config. Package Filter table is empty
        ConfigPackageFilter.Reset();
        Assert.AreEqual(0, ConfigPackageFilter.Count, 'The Config. Package Filter table should be empty');

        // [WHEN] Trying to create a Config. Package Filter for an existent table, but inexistent field id
        ConfigPackageFilterCreated := DataPrivacyMgmt.CreatePackageFilter(
            ConfigPackageCode, ExistentTableId, ExistentTableInexistentFieldId, FieldValue);

        // [THEN] The ConfigPackageFilterCreated variable should be false
        Assert.AreEqual(false, ConfigPackageFilterCreated, 'The 4th Config. Package Filter should NOT have been created');

        // [THEN] The Config. Package Filter table is empty
        ConfigPackageFilter.Reset();
        Assert.AreEqual(0, ConfigPackageFilter.Count, 'The Config. Package Filter table should be empty');

        // [WHEN] Trying to create a Config. Package Filter for an existent table and field id, 
        // corresponding to a BLOB field
        ConfigPackageFilterCreated := DataPrivacyMgmt.CreatePackageFilter(
            ConfigPackageCode, BLOBTableId, BLOBFieldId, FieldValue);

        // [THEN] The ConfigPackageFilterCreated variable should be false
        Assert.AreEqual(false, ConfigPackageFilterCreated, 'The 5th Config. Package Filter should NOT have been created');

        // [THEN] The Config. Package Filter table is empty
        ConfigPackageFilter.Reset();
        Assert.AreEqual(0, ConfigPackageFilter.Count, 'The Config. Package Filter table should be empty');

        // [WHEN] Trying to create a Config. Package Filter for an existent table and field id, 
        // corresponding to a GUID field
        ConfigPackageFilterCreated := DataPrivacyMgmt.CreatePackageFilter(
            ConfigPackageCode, GUIDTableId, GUIDFieldId, FieldValue);

        // [THEN] The ConfigPackageFilterCreated variable should be false
        Assert.AreEqual(false, ConfigPackageFilterCreated, 'The 6th Config. Package Filter should NOT have been created');

        // [THEN] The Config. Package Filter table is empty
        ConfigPackageFilter.Reset();
        Assert.AreEqual(0, ConfigPackageFilter.Count, 'The Config. Package Filter table should be empty');

        // [WHEN] Trying to create a Config. Package Filter for an existent table and field id, 
        // corresponding to an Integer field
        ConfigPackageFilterCreated := DataPrivacyMgmt.CreatePackageFilter(
            ConfigPackageCode, IntegerTableId, IntegerFieldId, '1');

        // [THEN] The ConfigPackageFilterCreated variable should be true
        Assert.AreEqual(true, ConfigPackageFilterCreated, 'The 8th Config. Package Filter should have been created');

        // [THEN] The Config. Package Filter table should contain exactly one entry
        ConfigPackageFilter.Reset();
        Assert.AreEqual(1, ConfigPackageFilter.Count, 'There should be 1 Config. Package Filter');

        // [WHEN] Trying to create a Config. Package Filter for an existent table and field id, 
        // corresponding to a Text field
        ConfigPackageFilterCreated := DataPrivacyMgmt.CreatePackageFilter(
            ConfigPackageCode, TextTableId, TextFieldId, FieldValue);

        // [THEN] The ConfigPackageFilterCreated variable should be true
        Assert.AreEqual(true, ConfigPackageFilterCreated, 'The 9th Config. Package Filter should have been created');

        // [THEN] The Config. Package Filter table should contain exactly two entries
        ConfigPackageFilter.Reset();
        Assert.AreEqual(2, ConfigPackageFilter.Count, 'There should be 2 Config. Package Filters');

        // [WHEN] Trying to create a Config. Package Filter for an existent table and field id, 
        // corresponding to a Code field
        ConfigPackageFilterCreated := DataPrivacyMgmt.CreatePackageFilter(
            ConfigPackageCode, CodeTableId, CodeFieldId, FieldValue);

        // [THEN] The ConfigPackageFilterCreated variable should be true
        Assert.AreEqual(true, ConfigPackageFilterCreated, 'The 10th Config. Package Filter should have been created');

        // [THEN] The Config. Package Filter table should contain exactly three entries
        ConfigPackageFilter.Reset();
        Assert.AreEqual(3, ConfigPackageFilter.Count, 'There should be 3 Config. Package Filters');

        // [WHEN] Trying to create a Config. Package Filter for an existent table and field id, 
        // corresponding to an Option field
        ConfigPackageFilterCreated := DataPrivacyMgmt.CreatePackageFilter(
            ConfigPackageCode, OptionTableId, OptionFieldId, 'Posting');

        // [THEN] The ConfigPackageFilterCreated variable should be true
        Assert.AreEqual(true, ConfigPackageFilterCreated, 'The 11th Config. Package Filter should have been created');

        // [THEN] The Config. Package Filter table should contain exactly four entries
        ConfigPackageFilter.Reset();
        Assert.AreEqual(4, ConfigPackageFilter.Count, 'There should be 4 Config. Package Filters');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitTableAndFieldIds()
    begin
        InexistentTableId := 8000;
        InexistentFieldId := 25;

        ExistentTableId := 2000000001;
        ExistentTableInexistentFieldId := 200000;

        BLOBTableId := 1062;
        BLOBFieldId := 13;

        GUIDTableId := 18;
        GUIDFieldId := 9003;

        TextTableId := 18;
        TextFieldId := 2;

        IntegerTableId := 27;
        IntegerFieldId := 9;

        CodeTableId := 15;
        CodeFieldId := 3;

        OptionTableId := 15;
        OptionFieldId := 4;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTableAndFieldIds()
    var
        "Field": Record "Field";
        CouldGetField: Boolean;
    begin
        InitTableAndFieldIds();

        // [WHEN] Trying to get a Field record corresponding to an inexistent table and field id
        CouldGetField := Field.Get(InexistentTableId, InexistentFieldId);

        // [THEN] The result is false
        Assert.AreEqual(false, CouldGetField, 'The Field should not exist');

        // [WHEN] Trying to get a Field record corresponding to an inexistent field id of an existent table id
        CouldGetField := Field.Get(ExistentTableId, ExistentTableInexistentFieldId);

        // [THEN] The result is false
        Assert.AreEqual(false, CouldGetField, 'The Field should not exist');

        // [WHEN] Trying to get a Field record corresponding to a BLOB field id
        CouldGetField := Field.Get(BLOBTableId, BLOBFieldId);

        // [THEN] The result is true
        Assert.AreEqual(true, CouldGetField, 'The BLOB Field does not exist');

        // [THEN] The field's type is BLOB
        Assert.AreEqual(Field.Type::BLOB, Field.Type, 'The Type of the BLOB Field is incorrect');

        // [WHEN] Trying to get a Field record corresponding to a Text field id
        CouldGetField := Field.Get(TextTableId, TextFieldId);

        // [THEN] The result is true
        Assert.AreEqual(true, CouldGetField, 'The Text Field does not exist');

        // [THEN] The field's type is Text
        Assert.AreEqual(Field.Type::Text, Field.Type, 'The Type of the Text Field is incorrect');

        // [WHEN] Trying to get a Field record corresponding to an Integer field id
        CouldGetField := Field.Get(IntegerTableId, IntegerFieldId);

        // [THEN] The result is true
        Assert.AreEqual(true, CouldGetField, 'The Integer Field does not exist');

        // [THEN] The field's type is Integer
        Assert.AreEqual(Field.Type::Integer, Field.Type, 'The Type of the Integer Field is incorrect');

        // [WHEN] Trying to get a Field record corresponding to a Code field id
        CouldGetField := Field.Get(CodeTableId, CodeFieldId);

        // [THEN] The result is true
        Assert.AreEqual(true, CouldGetField, 'The Code Field does not exist');

        // [THEN] The field's type is Code
        Assert.AreEqual(Field.Type::Code, Field.Type, 'The Type of the Code Field is incorrect');

        // [WHEN] Trying to get a Field record corresponding to an Option field id
        CouldGetField := Field.Get(OptionTableId, OptionFieldId);

        // [THEN] The result is true
        Assert.AreEqual(true, CouldGetField, 'The Option Field does not exist');

        // [THEN] The field's type is Option
        Assert.AreEqual(Field.Type::Option, Field.Type, 'The Type of the Option Field is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPackageCode()
    var
        ConfigPackage: Record "Config. Package";
        DataPrivacyTests: Codeunit "Data Privacy Tests";
        EntityTypeTableNo: Integer;
        EntityNo: Code[50];
        ActionType: Option "Export a data subject's data","Create a data privacy configuration package";
        PackageCode: Code[20];
    begin
        BINDSUBSCRIPTION(DataPrivacyTests);

        // [GIVEN] The Config. Package table is empty
        ConfigPackage.DeleteAll();

        // [GIVEN] An EntityNo variable whose length is greater than 17 characters
        EntityNo := '1234567891012141618';

        // [GIVEN] An EntityTypeTableNo variable that corresponds to the Customer table ID
        EntityTypeTableNo := 18;

        // [GIVEN] An ActionType varible assigned the value 'Export a data subject's data'
        ActionType := ActionType::"Export a data subject's data";

        // [WHEN] Getting the package code for the current values of EntityTypeTableNo, EntityNo and ActionType
        PackageCode := DataPrivacyMgmt.GetPackageCode(EntityTypeTableNo, EntityNo, ActionType);

        // [THEN] The package code should be 'CU*123456789101214161';
        Assert.AreEqual('CU*34567891012141618', PackageCode, 'The package code is incorrect');

        // [GIVEN] The ActionType variable becomes 'Create a data privacy configuration package'
        ActionType := ActionType::"Create a data privacy configuration package";

        // [WHEN] Getting the package code for the current values of EntityTypeTableNo, EntityNo and ActionType
        PackageCode := DataPrivacyMgmt.GetPackageCode(EntityTypeTableNo, EntityNo, ActionType);

        // [THEN] The package code should be 'CUS123456789101214161';
        Assert.AreEqual('CUS34567891012141618', PackageCode, 'The package code is incorrect');

        // [GIVEN] The Config. Package table contains an entry with the Code PackageCode
        ConfigPackage.Init();
        ConfigPackage.Code := PackageCode;
        ConfigPackage.Insert();

        // [GIVEN] The ActionType variable becomes 'Export a data subject's data'
        ActionType := ActionType::"Export a data subject's data";

        // [WHEN] Getting the package code for the current values of EntityTypeTableNo, EntityNo and ActionType
        PackageCode := DataPrivacyMgmt.GetPackageCode(EntityTypeTableNo, EntityNo, ActionType);

        // [THEN] The package code should be 'CUS123456789101214161';
        Assert.AreEqual('CUS34567891012141618', PackageCode, 'The package code is incorrect');

        // [GIVEN] An EntityNo Code variable whose length is less than 17 characters
        EntityNo := 'R2D2';

        // [WHEN] Getting the package code for the current values of EntityTypeTableNo, EntityNo and ActionType
        PackageCode := DataPrivacyMgmt.GetPackageCode(EntityTypeTableNo, EntityNo, ActionType);

        // [THEN] The package code should be 'CU*R2D2';
        Assert.AreEqual('CU*R2D2', PackageCode, 'The package code is incorrect');

        // [GIVEN] The Config. Package table is empty
        ConfigPackage.DeleteAll();

        // [GIVEN] An EntityTypeTableNo variable that corresponds to a non-master table
        EntityTypeTableNo := 27;

        // [WHEN] Getting the package code for the current values of EntityTypeTableNo, EntityNo and ActionType
        PackageCode := DataPrivacyMgmt.GetPackageCode(EntityTypeTableNo, EntityNo, ActionType);

        // [THEN] OnAfterGetPackageCodeSubscriber should be called and insert a new Config. Package
        // with the code PackageCodeTempTxt
        ConfigPackage.Reset();
        Assert.AreEqual(1, ConfigPackage.Count, 'There should be exactly one entry in the Config. Package table');

        if ConfigPackage.FindFirst() then
            Assert.AreEqual(PackageCodeTempTxt, ConfigPackage.Code, 'The Code of the Config. Package is incorrect');

        // [THEN] The Package Code should be PackageCodeTempTxt
        Assert.AreEqual(PackageCodeTempTxt, PackageCode, 'The package code is incorrect');

        UNBINDSUBSCRIPTION(DataPrivacyTests);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Privacy Mgmt", 'OnAfterGetPackageCode', '', false, false)]
    local procedure OnAfterGetPackageCodeSubscriber(EntityTypeTableNo: Integer; EntityNo: Code[50]; ActionType: Option "Export a data subject's data","Create a data privacy configuration package"; var PackageCodeTemp: Code[20]; var PackageCodeKeep: Code[20])
    var
        ConfigPackage: Record "Config. Package";
    begin
        ConfigPackage.Init();
        ConfigPackage.Code := PackageCodeTempTxt;
        ConfigPackage.Insert();

        PackageCodeKeep := PackageCodeKeepTxt;
        PackageCodeTemp := PackageCodeTempTxt;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageData: Record "Config. Package Data";
        PackageCode: Code[20];
    begin
        // [GIVEN] A package code
        PackageCode := 'hgjhgsdblah';

        // [GIVEN] A record in the Config. Package table
        ConfigPackage.DeleteAll();

        ConfigPackage.Init();
        ConfigPackage.Code := PackageCode;
        ConfigPackage.Insert();

        Assert.AreEqual(1, ConfigPackage.Count, 'There should be exactly one entry in the Config. Package table');

        // [GIVEN] A record in the Config. Package Data table with the same Code as the Config. Package Code
        ConfigPackageData.DeleteAll();

        ConfigPackageData.Init();
        ConfigPackageData."Package Code" := PackageCode;
        ConfigPackageData.Insert();

        Assert.AreEqual(1, ConfigPackageData.Count, 'There should be exactly one entry in the Config. Package Data table');

        // [WHEN] Deleting the package with the code PackageCode
        DataPrivacyMgmt.DeletePackage(PackageCode);

        // [THEN] Both the Config. Package and the Config. Package Data tables should be empty
        ConfigPackage.Reset();
        Assert.AreEqual(0, ConfigPackage.Count, 'The Config. Package table is empty');

        ConfigPackageData.Reset();
        Assert.AreEqual(0, ConfigPackageData.Count, 'The Config. Package Data table is empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDataForChangeLogEntries()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        ChangeLogEntry: Record "Change Log Entry";
        PackageCode: Code[20];
        EntityNo: Code[50];
        TableNo: Integer;
    begin
        // [GIVEN] The Config. Package, Config. Package Table and Config. Package Filter tables are empty
        ConfigPackage.DeleteAll();
        ConfigPackageTable.DeleteAll();
        ConfigPackageFilter.DeleteAll();

        // [GIVEN] A package code, an entity number and a table number
        PackageCode := 'codeghf';
        EntityNo := 'US123';
        TableNo := 18;

        // [GIVEN] A Config. Package entry with the Code PackageCode
        ConfigPackage.Init();
        ConfigPackage.Code := PackageCode;
        ConfigPackage.Insert();

        // [WHEN] Creating data for ChangeLog entries
        DataPrivacyMgmt.CreateDataForChangeLogEntries(PackageCode, EntityNo, TableNo);

        // [THEN] A new Config. Package Table is created
        Assert.AreEqual(1, ConfigPackageTable.Count, 'There should be exactly one entry in the Config. Package Table table');

        if ConfigPackageTable.FindFirst() then begin
            // [THEN] The Config. Package Table's Package Code field is PackageCode
            Assert.AreEqual(PackageCode, ConfigPackageTable."Package Code", 'The Package Code is incorrect');

            // [THEN] The Config Package Table's Table Id is the same as the Change Log Entry's ID
            Assert.AreEqual(DATABASE::"Change Log Entry", ConfigPackageTable."Table ID",
              'The Table ID is incorrect');
        end;

        // [THEN] The Config. Package Filter table contains exactly 2 entries
        Assert.AreEqual(2, ConfigPackageFilter.Count, 'The Config. Package Filter table should contain exactly 2 entries');

        // [THEN] One of the Config. Package Filter's Field Filter field should be TableNo
        ConfigPackageFilter.SetRange("Field Filter", Format(TableNo));
        Assert.AreEqual(1, ConfigPackageFilter.Count,
          'There should be a Config. Package Filter with Field Filter specified by TableNo');

        if ConfigPackageFilter.FindFirst() then begin
            // [THEN] The Config. Package Filter's fields are set correctly
            Assert.AreEqual(PackageCode, ConfigPackageFilter."Package Code", 'The Package Code is incorrect');
            Assert.AreEqual(DATABASE::"Change Log Entry", ConfigPackageFilter."Table ID",
              'The Table ID is incorrect');
            Assert.AreEqual(ChangeLogEntry.FieldNo("Table No."), ConfigPackageFilter."Field ID",
              'The Field ID is incorrect');
        end;

        // [THEN] One of the Config. Package Filter's Field Filter field should be EntityNo
        ConfigPackageFilter.SetRange("Field Filter", Format(EntityNo));
        Assert.AreEqual(1, ConfigPackageFilter.Count,
          'There should be a Config. Package Filter with Field Filter specified by EntityNo');

        if ConfigPackageFilter.FindFirst() then begin
            // [THEN] The Config. Package Filter's fields are set correctly
            Assert.AreEqual(PackageCode, ConfigPackageFilter."Package Code", 'The Package Code is incorrect');
            Assert.AreEqual(DATABASE::"Change Log Entry", ConfigPackageFilter."Table ID",
              'The Table ID is incorrect');
            Assert.AreEqual(ChangeLogEntry.FieldNo("Primary Key Field 1 Value"), ConfigPackageFilter."Field ID",
              'The Field ID is incorrect');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageFilter: Record "Config. Package Filter";
        Customer: Record Customer;
        DataSensitivity: Record "Data Sensitivity";
        ChangeLogEntry: Record "Change Log Entry";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        DataPrivacyMgmt: Codeunit "Data Privacy Mgmt";
        TableNo: Integer;
        EntityTypeTableNo: Integer;
        EntityNo: Code[50];
        PackageCode: Code[20];
        PackageName: Code[20];
        DataSensitivityOption: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified;
        TablePrimaryKeyId: Integer;
        SensitiveFieldId1: Integer;
        SensitiveFieldId2: Integer;
        CompanyConfidentialFieldId: Integer;
    begin
        // [GIVEN] The Config. Package, Config. Package Table, Config. Package Filter and Config. Package Field tables are empty
        ConfigPackage.DeleteAll();
        ConfigPackageTable.DeleteAll();
        ConfigPackageField.DeleteAll();
        ConfigPackageFilter.DeleteAll();

        // [GIVEN] A table number corresponding to the Customer table id
        TableNo := DATABASE::Customer;

        // [GIVEN] The table number of the Data Privacy entity corresponding to TableNo (in this case it is the Customer table id)
        EntityTypeTableNo := DATABASE::Customer;

        // [GIVEN] A TablePrimaryKeyId variable that denotes the primary key ID of the Customer table
        TablePrimaryKeyId := 1;

        // [GIVEN] An EntityNo variable
        EntityNo := '123';

        // [GIVEN] The Customer table contains a single entry, with No. EntityNo
        Customer.DeleteAll();

        Customer.Init();
        Customer."No." := CopyStr(EntityNo, 1, 20);
        Customer.Insert();

        // [GIVEN] The Data Sensitivity table contains a few entries for fields in the Customer table
        SensitiveFieldId1 := 2;
        SensitiveFieldId2 := 3;
        CompanyConfidentialFieldId := 4;

        DataSensitivity.DeleteAll();
        DataClassificationMgt.InsertDataSensitivityForField(TableNo, SensitiveFieldId1, DataSensitivity."Data Sensitivity"::Sensitive);
        DataClassificationMgt.InsertDataSensitivityForField(TableNo, SensitiveFieldId2, DataSensitivity."Data Sensitivity"::Sensitive);
        DataClassificationMgt.InsertDataSensitivityForField(TableNo,
          CompanyConfidentialFieldId, DataSensitivity."Data Sensitivity"::"Company Confidential");

        // [GIVEN] A package code and name
        PackageCode := 'CUS123';
        PackageName := 'Privacy package';

        // [WHEN] Creating the package for the above defined Customer
        DataPrivacyMgmt.CreatePackage(TableNo, EntityTypeTableNo, EntityNo, PackageCode, PackageName, DataSensitivityOption::Sensitive);

        // [THEN] There should exist a Config. Package with the Code PackageCode and Package Name PackageName
        Assert.Equal(1, ConfigPackage.Count);
        if ConfigPackage.FindFirst() then begin
            Assert.AreEqual(PackageCode, ConfigPackage.Code, 'The Config. Package Code is incorrect');
            Assert.AreEqual(PackageName, ConfigPackage."Package Name", 'The Config. Package Name is incorrect');
        end;

        // [THEN] There should exist a Config. Package Table with the Code PackageCode and Table ID EntityTypeTableNo
        ConfigPackageTable.SetRange("Table ID", EntityTypeTableNo);
        Assert.AreEqual(1, ConfigPackageTable.Count,
          'There should only be one Config. Package Table with the Table ID 18');
        if ConfigPackageTable.FindFirst() then
            Assert.AreEqual(PackageCode, ConfigPackageTable."Package Code",
              'The Package Code of the Config. Package Table is incorrect');

        // [THEN] The primary key of the Customer table (the No. field) should have a corresponding
        // Config. Package Field and Config. Package Filter
        ConfigPackageField.SetRange("Field ID", TablePrimaryKeyId);
        ConfigPackageField.SetRange("Table ID", EntityTypeTableNo);
        Assert.AreEqual(1, ConfigPackageField.Count,
          'There should be exactly one Config. Package Field corresponding to the No. field of the Customer table');
        if ConfigPackageField.FindFirst() then
            Assert.AreEqual(PackageCode, ConfigPackageField."Package Code", 'the Package Code of the Config. Package Field is incorrect');

        ConfigPackageFilter.SetRange("Field ID", TablePrimaryKeyId);
        ConfigPackageFilter.SetRange("Table ID", EntityTypeTableNo);
        Assert.AreEqual(1, ConfigPackageFilter.Count,
          'There should be exactly one Config. Package Filter corresponding to the No. field of the Customer table');
        if ConfigPackageFilter.FindFirst() then
            Assert.AreEqual(PackageCode, ConfigPackageFilter."Package Code", 'the Package Code of the Config. Package Filter is incorrect');

        // [THEN] There should be a Config. Package Field for both Sensitive fields in the Customer table, 
        // but none for the Company Confidential field
        ConfigPackageField.SetRange("Field ID", SensitiveFieldId1);
        Assert.AreEqual(1, ConfigPackageField.Count, 'There should be a Config. Package Field for the first Sensitive field');

        ConfigPackageField.SetRange("Field ID", SensitiveFieldId2);
        Assert.AreEqual(1, ConfigPackageField.Count, 'There should be a Config. Package Field for the second Sensitive field');

        ConfigPackageField.SetRange("Field ID", CompanyConfidentialFieldId);
        Assert.AreEqual(0, ConfigPackageField.Count,
          'There should NOT be any Config. Package Field for the Company Confidential field');

        // [THEN] There should be at least one entry in the Config. Package Field table for a table that
        // our current table (with ID EntityTypeTableNo) has a relation to
        ConfigPackageField.Reset();
        ConfigPackageField.SetRange("Table ID", 21);
        Assert.AreNotEqual(0, ConfigPackageField.Count,
          'There should be at least one entry in the Config. Package Field table for Table ID 21');

        // [THEN] A field from a related table to the table with ID EntityTypeTableID that is normal and is of type
        // Integer, Text, Code or Option must be represented in the Config. Package Field
        ConfigPackageField.Reset();
        ConfigPackageField.SetRange("Table ID", 21);
        ConfigPackageField.SetRange("Field ID", 3);

        Assert.AreEqual(1, ConfigPackageField.Count,
          'The Config. Package Field table must contain an entry for table 21 field 3');

        // [THEN] The Config. Package Table table should contain an entry for the Change Log Entry table
        ConfigPackageTable.Reset();
        ConfigPackageTable.SetRange("Table ID", DATABASE::"Change Log Entry");

        Assert.AreEqual(1, ConfigPackageTable.Count,
          'There must be an entry in the Config. Package Table table for the Change Log Entry table');

        // [THEN] There must be 2 entries in the Config. Package Filter table for Change Log Entry table
        ConfigPackageFilter.Reset();
        ConfigPackageFilter.SetRange("Table ID", DATABASE::"Change Log Entry");
        ConfigPackageFilter.SetRange("Field ID", ChangeLogEntry.FieldNo("Table No."));
        Assert.AreEqual(1, ConfigPackageTable.Count,
          'There must be oen entry in the Config. Package Filter table for the Table No. field of the Change Log Entry table');

        ConfigPackageFilter.SetRange("Field ID", ChangeLogEntry.FieldNo("Primary Key Field 1 Value"));
        Assert.AreEqual(1, ConfigPackageTable.Count, StrSubstNo('%1%2',
            'There must be oen entry in the Config. Package Filter table for the Primary Key Field 1 ',
            'Value field of the Change Log Entry table'));

        // [THEN] The Config. Package Table table should contain an entry for the Sales Invoice Header table
        ConfigPackageTable.Reset();
        ConfigPackageTable.SetRange("Table ID", Database::"Sales Invoice Header");
        Assert.AreEqual(1, ConfigPackageTable.Count(),
          'There must be an entry in the Config. Package Table table for the Sales Invoice Header table');
        // [THEN] There must be 2 entries in the Config. Package Filter table for Sales Invoice Header table  (TFS 346990)
        ConfigPackageFilter.Reset();
        ConfigPackageFilter.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageFilter.SetRange("Table ID", Database::"Sales Invoice Header");
        Assert.AreEqual(2, ConfigPackageFilter.Count(),
          'There must be 2 entries in the Config. Package Filter table for the Sales Invoice Header table.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPrivacyEntityKeyFieldAndTableNo()
    var
        DataPrivacyMgmt: Codeunit "Data Privacy Mgmt";
        EntityKeyFieldNo: Integer;
        EntityTableNo: Integer;
    begin
        // [GIVEN] A Data Privacy Entity's table number
        EntityTableNo := DATABASE::"User Setup";

        // [WHEN] Getting the privacy entity's key and table no
        DataPrivacyMgmt.GetPrivacyEntityKeyFieldAndTableNo(EntityKeyFieldNo, EntityTableNo);

        // [THEN] The EntityTableNo should be the User Setup's table ID and the EntityKeyFieldNo should be 1
        Assert.AreEqual(DATABASE::"User Setup", EntityTableNo,
          'The table ID of the entity should be the ID of the User Setup table');
        Assert.AreEqual(1, EntityKeyFieldNo, 'The Key Field No. of the Entity should be 1');

        // [GIVEN] A Data Privacy Entity's table number
        EntityTableNo := DATABASE::Customer;

        // [WHEN] Getting the privacy entity's key and table no
        DataPrivacyMgmt.GetPrivacyEntityKeyFieldAndTableNo(EntityKeyFieldNo, EntityTableNo);

        // [THEN] The EntityTableNo should be the Customer's table ID and the EntityKeyFieldNo should be 1
        Assert.AreEqual(DATABASE::Customer, EntityTableNo,
          'The table ID of the entity should be the ID of the Customer table');
        Assert.AreEqual(1, EntityKeyFieldNo, 'The Key Field No. of the Entity should be 1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFilterDataSensitivityByDataSensitivityOption()
    var
        DataSensitivity: Record "Data Sensitivity";
        DataPrivacyMgmt: Codeunit "Data Privacy Mgmt";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
        DataSensitivityOption: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified;
    begin
        // [GIVEN] A table id
        TableNo := 27;

        // [GIVEN] The Data Sensitivity table is empty
        DataSensitivity.DeleteAll();

        // [WHEN] Filtering the Data Sensitivity table for Sensitive entries
        DataPrivacyMgmt.FilterDataSensitivityByDataSensitivityOption(
          DataSensitivity, TableNo, DataSensitivityOption::Sensitive);

        // [THEN] The Data Sensitivity table should contain 0 entries
        Assert.AreEqual(0, DataSensitivity.Count, 'The Data Sensitivity table is empty');

        // [GIVEN] The Data Sensitivity table contains 2 sensitive fields, 1 personal field, 
        // 2 company confidential fields, 1 normal field and 1 unclassified field
        DataClassificationMgt.InsertDataSensitivityForField(TableNo, 1, DataSensitivity."Data Sensitivity"::Sensitive);
        DataClassificationMgt.InsertDataSensitivityForField(TableNo, 2, DataSensitivity."Data Sensitivity"::Sensitive);
        DataClassificationMgt.InsertDataSensitivityForField(TableNo, 3, DataSensitivity."Data Sensitivity"::Personal);
        DataClassificationMgt.InsertDataSensitivityForField(TableNo, 4, DataSensitivity."Data Sensitivity"::"Company Confidential");
        DataClassificationMgt.InsertDataSensitivityForField(TableNo, 5, DataSensitivity."Data Sensitivity"::"Company Confidential");
        DataClassificationMgt.InsertDataSensitivityForField(TableNo, 6, DataSensitivity."Data Sensitivity"::Normal);
        DataClassificationMgt.InsertDataSensitivityForField(TableNo, 7, DataSensitivity."Data Sensitivity"::Unclassified);

        // [WHEN] Filtering the Data Sensitivity table for Sensitive entries
        DataPrivacyMgmt.FilterDataSensitivityByDataSensitivityOption(
          DataSensitivity, TableNo, DataSensitivityOption::Sensitive);

        // [THEN] The Data Sensitivity table should contain 2 entries
        Assert.AreEqual(2, DataSensitivity.Count, 'The Data Sensitivity table contains 2 Sensitive entries');

        // [WHEN] Filtering the Data Sensitivity table for Personal entries
        DataPrivacyMgmt.FilterDataSensitivityByDataSensitivityOption(
          DataSensitivity, TableNo, DataSensitivityOption::Personal);

        // [THEN] The Data Sensitivity table should contain 3 entries (2 Sensitive + 1 Personal)
        Assert.AreEqual(3, DataSensitivity.Count, 'The Data Sensitivity table contains 2 Sensitive entries and 1 Personal one');

        // [WHEN] Filtering the Data Sensitivity table for Company Confidential entries
        DataPrivacyMgmt.FilterDataSensitivityByDataSensitivityOption(
          DataSensitivity, TableNo, DataSensitivityOption::"Company Confidential");

        // [THEN] The Data Sensitivity table should contain 5 entries (2 Sensitive + 1 Personal + 2 Company Confidential)
        Assert.AreEqual(5, DataSensitivity.Count,
          'The Data Sensitivity table contains 2 Sensitive entries, 1 Personal one and 2 Company Confidential');

        // [WHEN] Filtering the Data Sensitivity table for Normal entries
        DataPrivacyMgmt.FilterDataSensitivityByDataSensitivityOption(
          DataSensitivity, TableNo, DataSensitivityOption::Normal);

        // [THEN] The Data Sensitivity table should contain 6 entries
        // (2 Sensitive + 1 Personal + 2 Company Confidential + 1 Normal)
        Assert.AreEqual(6, DataSensitivity.Count,
          'The Data Sensitivity table contains 2 Sensitive entries, 1 Personal one, 2 Company Confidential and 1 Normal');

        // [WHEN] Filtering the Data Sensitivity table for Unclassified entries
        DataPrivacyMgmt.FilterDataSensitivityByDataSensitivityOption(
          DataSensitivity, TableNo, DataSensitivityOption::Unclassified);

        // [THEN] The Data Sensitivity table should contain 1 entry
        Assert.AreEqual(1, DataSensitivity.Count, 'The Data Sensitivity table contains 1 unclassified entry');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertPackageTable()
    var
        ConfigPackageTable: Record "Config. Package Table";
        DummyConfigPackage: Record "Config. Package";
        PackageCode: Code[20];
        TableId: Integer;
    begin
        // [SCENARIO 346990] DataPrivacyMgmt.InsertPackageTable() sets ConfigPackageTable."Cross-Column Filter" = true
        PackageCode := LibraryUtility.GenerateGUID();
        TableId := 27;
        DataPrivacyMgmt.CreateConfigPackage(DummyConfigPackage, PackageCode, LibraryUtility.GenerateGUID());
        DataPrivacyMgmt.CreatePackageTable(PackageCode, TableId);

        DataPrivacyMgmt.InsertPackageTable(PackageCode, TableId, false);

        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageTable.FindFirst();
        Assert.AreEqual(true, ConfigPackageTable."Cross-Column Filter", '"Cross-Column Filter" is expected to be TRUE');
    end;
}

