codeunit 139166 "Integration Record Synch. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Integration Record Synch.]
    end;

    var
        Assert: Codeunit Assert;
        LibraryMarketing: Codeunit "Library - Marketing";

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTransferFieldsNewRecord()
    var
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceTableRecRef: RecordRef;
        DestinationTableRecRef: RecordRef;
    begin
        // [SCENARIO] Synchronize Integration Table with Nav Table if destination record does not exist
        Initialize();

        // [GIVEN] Source row is filled, Destination row is empty
        PrepareSourceRowAndDestinationRefs(SourceTableRecRef, DestinationTableRecRef);

        // [GIVEN] Integration Field Mappping is defined
        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, true);

        // [WHEN] Run IntegrationRecordSynch for the source row and the destination row
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Commit();
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the transfer to return true');
        // [THEN] Field values are copied and WasModified flags is true
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified(), 'Expected the modified flag to be set');

        ValidateComparisonTypeRow(SourceTableRecRef, DestinationTableRecRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTransferFieldsExistingRecord()
    var
        TempComparisonType: Record "Comparison Type" temporary;
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceTableRecRef: RecordRef;
        DestinationTableRecRef: RecordRef;
        SourceFieldRef: FieldRef;
    begin
        // [SCENARIO] Synchronize Integration Table with Nav Table if destination record already exists
        Initialize();

        // [GIVEN] Source row is synced with Destination row once
        PrepareSourceRowAndDestinationRefs(SourceTableRecRef, DestinationTableRecRef);
        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, true);
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Commit();
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the first transfer to succeed');
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified(), 'Expected first transfer to set the modified flag to true');

        // Re-create the fieldmapping without the primary key default. If we do not the all transfers will reset the primary key to default value.
        TempIntegrationFieldMapping.DeleteAll();
        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, false);

        // [GIVEN] Destination row has already been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, true);
        Commit();
        // [WHEN] Run IntegrationRecordSynch, where "Copy Only Modified" is 'true'
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the second transfer to succeed');
        // [THEN] WasModified flag will be 'false'
        Assert.IsFalse(IntegrationRecordSynch.GetWasModified(), 'Expected second transfer to set the modified flag to false');

        // [GIVEN] Destination row has already been synchronized but one value has changed.
        SourceFieldRef := SourceTableRecRef.Field(TempComparisonType.FieldNo("Text Field"));
        SourceFieldRef.Value := 'This is another text';
        SourceTableRecRef.Modify();
        Commit();
        // [WHEN] Run IntegrationRecordSynch, where "Copy Only Modified" is 'true'
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, true);
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the third transfer to succeed');
        // [THEN] Modified field should be transfered and WasModified flags set to 'true'
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified(), 'Expected third transfer to set the modified flag to true');

        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Commit();
        // [WHEN] Run IntegrationRecordSynch, where "Copy Only Modified" is 'false'
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the fourth transfer to succeed');
        // [THEN] All fields should be copied and WasModified flags should be 'true'
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified(), 'Expected fourth transfer to set the modified flag to true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTransferFieldsFailOnMissingParameters()
    var
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceTableRecRef: RecordRef;
        DestinationTableRecRef: RecordRef;
    begin
        // [SCENARIO] Synchronize Integration Table with Nav Table if parameters are not defined correctly
        Initialize();
        Commit();
        // [GIVEN] Process parameters has not been set
        // [WHEN] Copying source row fields to Destination row
        // [THEN] Processing should not succeed
        Assert.IsFalse(IntegrationRecordSynch.Run(), 'Expected run to fail');

        // [GIVEN] Processing parameters are invalid
        // [WHEN] Copying source row fields to Destination row
        // [THEN] Processing should not succeed
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Assert.IsFalse(IntegrationRecordSynch.Run(), 'Expected run to fail when set with empty parameters');

        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, true);
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        // [GIVEN] Source has no data
        // [WHEN] Copying source row fields to Destination row
        // [THEN] Processing should not succeed
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Assert.IsFalse(IntegrationRecordSynch.Run(), 'Expected run to fail when set with empty source and Destination');

        // [GIVEN] Destination has not been initialized
        // [WHEN] Copying source row fields to Destination row
        // [THEN] Processing should not succeed
        SourceTableRecRef.Open(DATABASE::Customer);
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Assert.IsFalse(IntegrationRecordSynch.Run(), 'Expected run to fail when set with empty Destination');

        // [GIVEN] Destination does not have the expected fields
        // [WHEN] Copying source row fields to Destination row
        // [THEN] Processing should not succeed
        DestinationTableRecRef.Open(DATABASE::Contact);
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Assert.IsFalse(IntegrationRecordSynch.Run(), 'Expected run to fail when Destination does not have the required fields');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanTransferCalculatedFields()
    var
        Contact: Record Contact;
        ValidationContact: Record Contact;
        JobResponsibility: Record "Job Responsibility";
        ContactJobResponsibility: Record "Contact Job Responsibility";
        ComparisonType: Record "Comparison Type";
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        SourceFieldRef: FieldRef;
        ExpectedValue: Integer;
    begin
        // [FEATURE] [FlowField]
        // [SCENARIO] IntegrationRecordSynch should sync the value of calculated flowfield
        Initialize();
        // [GIVEN] Destination row is empty
        ComparisonType.Init();
        DestinationRecordRef.GetTable(ComparisonType);
        // [GIVEN] Source record has a calculated flowfield
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateJobResponsibility(JobResponsibility);
        ContactJobResponsibility.Init();
        ContactJobResponsibility."Contact No." := Contact."No.";
        ContactJobResponsibility."Contact Name" := Contact.Name;
        ContactJobResponsibility."Contact Company Name" := Contact."Company Name";
        ContactJobResponsibility."Job Responsibility Code" := JobResponsibility.Code;
        ContactJobResponsibility."Job Responsibility Description" := JobResponsibility.Description;
        ContactJobResponsibility.Insert();
        // [GIVEN] The source flowfield is mapped to a normal destination field
        TempIntegrationFieldMapping.Init();
        TempIntegrationFieldMapping."No." := 1;
        TempIntegrationFieldMapping."Integration Table Mapping Name" := 'Temp Mapping';
        TempIntegrationFieldMapping."Source Field No." := Contact.FieldNo("No. of Job Responsibilities");
        TempIntegrationFieldMapping."Destination Field No." := ComparisonType.FieldNo("Integer Field");
        TempIntegrationFieldMapping."Validate Destination Field" := false;
        TempIntegrationFieldMapping.Bidirectional := false;
        TempIntegrationFieldMapping."Constant Value" := '';
        TempIntegrationFieldMapping."Not Null" := false;
        TempIntegrationFieldMapping.Insert();

        ValidationContact.Get(Contact."No.");
        ValidationContact.CalcFields("No. of Job Responsibilities");
        ExpectedValue := ValidationContact."No. of Job Responsibilities";
        Assert.AreEqual(
          1, ValidationContact."No. of Job Responsibilities", 'Expected the calulated field to have a value after calculation.');
        Assert.AreEqual(
          0, Contact."No. of Job Responsibilities", 'Did not expect the calculated field to have a value before calculation.');

        // Validate field class. This could change if we decide to change/expose the field class option
        // causing the production code to fail
        SourceRecordRef.GetTable(Contact);
        SourceFieldRef := SourceRecordRef.Field(Contact.FieldNo("No. of Job Responsibilities"));
        Assert.AreEqual(
          'FlowField', Format(SourceFieldRef.Class, 0, 9), 'Expected the formatting field class Flowfield to match expected value.');
        SourceFieldRef := SourceRecordRef.Field(Contact.FieldNo("No."));
        Assert.AreEqual('Normal', Format(SourceFieldRef.Class, 0, 9), 'Expected the formatting field class Normal to match expected value.');
        SourceFieldRef := SourceRecordRef.Field(Contact.FieldNo("Date Filter"));
        Assert.AreEqual(
          'FlowFilter', Format(SourceFieldRef.Class, 0, 9), 'Expected the formatting field class FlowFilter to match expected value.');

        // [WHEN] Run IntegrationRecordSynch, where "Copy Only Modified" is 'false'
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        IntegrationRecordSynch.SetParameters(SourceRecordRef, DestinationRecordRef, false);
        Commit();
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the transfer to succeed');

        // [THEN] Calculated flowfield value will be transfered.
        DestinationRecordRef.SetTable(ComparisonType);
        Assert.AreEqual(ExpectedValue, ComparisonType."Integer Field", 'Expected the No. of Job Responsibilities to be transfered');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyModifiedFlagsAfterFieldsTransferWithUnchangedUnmappedField()
    var
        SourceComparisonType: Record "Comparison Type";
        DestinationComparisonType: Record "Comparison Type";
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceTableRecRef: RecordRef;
        DestinationTableRecRef: RecordRef;
    begin
        // [SCENARIO] Transfer fields with the unchanged unmapped field
        Initialize();

        // [GIVEN] Source row
        CreateComparisonTypeRow(SourceComparisonType);
        SourceTableRecRef.GetTable(SourceComparisonType);
        // [GIVEN] Destination row
        DestinationComparisonType."Key" := SourceComparisonType."Key" + 1;
        DestinationComparisonType.Insert();
        DestinationTableRecRef.GetTable(DestinationComparisonType);
        // [GIVEN] No mapping for the Guid Field
        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, false);
        TempIntegrationFieldMapping.SetRange("Source Field No.", SourceComparisonType.FieldNo("GUID Field"));
        TempIntegrationFieldMapping.DeleteAll();
        TempIntegrationFieldMapping.Reset();
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        // [GIVEN] Destination row has not been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Commit();

        // [WHEN] Transfer the fields the first time
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the first transfer to succeed');
        // [THEN] The flag indicates that fields have been modified
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified(), 'Expected the first transfer to set the any field modified flag to true');
        // [THEN] The flag indicates that bidirectional fields have not been modified
        Assert.IsFalse(IntegrationRecordSynch.GetWasBidirectionalFieldModified(), 'Expected the first transfer to set the bidirectional field modified flag to false');

        // [GIVEN] Destination row has already been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, true);
        // [GIVEN] The Guid Field (unmapped) is not changed
        Commit();

        // [WHEN] Transfer the fields the second time
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the second transfer to succeed');
        // [THEN] The flag indicates that fields have not been modified
        Assert.IsFalse(IntegrationRecordSynch.GetWasModified(), 'Expected the second transfer to set the any field modified flag to false');
        // [THEN] The flag indicates that bidirectional fields have not been modified
        Assert.IsFalse(IntegrationRecordSynch.GetWasBidirectionalFieldModified(), 'Expected the second transfer to set the bidirectional field modified flag to false');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyModifiedFlagsAfterFieldsTransferWithChangedUnidirectionalField()
    var
        SourceComparisonType: Record "Comparison Type";
        DestinationComparisonType: Record "Comparison Type";
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceTableRecRef: RecordRef;
        DestinationTableRecRef: RecordRef;
    begin
        // [SCENARIO] Transfer fields with the changed unidirectional field
        Initialize();

        // [GIVEN] Source row
        CreateComparisonTypeRow(SourceComparisonType);
        SourceTableRecRef.GetTable(SourceComparisonType);
        // [GIVEN] Destination row
        DestinationComparisonType."Key" := SourceComparisonType."Key" + 1;
        DestinationComparisonType.Insert();
        DestinationTableRecRef.GetTable(DestinationComparisonType);
        // [GIVEN] Unidirectional mapping for the Guid Field
        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, false);
        TempIntegrationFieldMapping.SetRange("Source Field No.", SourceComparisonType.FieldNo("GUID Field"));
        TempIntegrationFieldMapping.ModifyAll(Bidirectional, false);
        TempIntegrationFieldMapping.Reset();
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        // [GIVEN] Destination row has not been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Commit();

        // [WHEN] Transfer the fields the first time
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the first transfer to succeed');
        // [THEN] The flag indicates that fields have been modified
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified(), 'Expected the first transfer to set the any field modified flag to true');
        // [THEN] The flag indicates that bidirectional fields have not been modified
        Assert.IsFalse(IntegrationRecordSynch.GetWasBidirectionalFieldModified(), 'Expected the first transfer to set the bidirectional field modified flag to false');

        // [GIVEN] Destination row has already been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, true);
        // [GIVEN] The Guid Field (unidirectional) is changed
        DestinationTableRecRef.Find();
        DestinationTableRecRef.Field(SourceComparisonType.FieldNo("Guid Field")).Value := CreateGuid();
        DestinationTableRecRef.Modify();
        Commit();

        // [WHEN] Transfer the fields the second time
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the second transfer to succeed');
        // [THEN] The flag indicates that fields have been modified
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified(), 'Expected the second transfer to set the any field modified flag to true');
        // [THEN] The flag indicates that bidirectional fields have not been modified
        Assert.IsFalse(IntegrationRecordSynch.GetWasBidirectionalFieldModified(), 'Expected the second transfer to set the bidirectional field modified flag to false');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyModifiedFlagsAfterFieldsTransferWithUnchangedUnidirectionalField()
    var
        SourceComparisonType: Record "Comparison Type";
        DestinationComparisonType: Record "Comparison Type";
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceTableRecRef: RecordRef;
        DestinationTableRecRef: RecordRef;
    begin
        // [SCENARIO] Transfer fields with the unchanged unidirectional field
        Initialize();

        // [GIVEN] Source row
        CreateComparisonTypeRow(SourceComparisonType);
        SourceTableRecRef.GetTable(SourceComparisonType);
        // [GIVEN] Destination row
        DestinationComparisonType."Key" := SourceComparisonType."Key" + 1;
        DestinationComparisonType.Insert();
        DestinationTableRecRef.GetTable(DestinationComparisonType);
        // [GIVEN] Unidirectional mapping for the Guid Field
        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, false);
        TempIntegrationFieldMapping.SetRange("Source Field No.", SourceComparisonType.FieldNo("GUID Field"));
        TempIntegrationFieldMapping.ModifyAll(Bidirectional, false);
        TempIntegrationFieldMapping.Reset();
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        // [GIVEN] Destination row has not been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Commit();

        // [WHEN] Transfer the fields the first time
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the first transfer to succeed');
        // [THEN] The flag indicates that fields have been modified
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified(), 'Expected the first transfer to set the any field modified flag to true');
        // [THEN] The flag indicates that bidirectional fields have not been modified
        Assert.IsFalse(IntegrationRecordSynch.GetWasBidirectionalFieldModified(), 'Expected the first transfer to set the bidirectional field modified flag to false');

        // [GIVEN] Destination row has already been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, true);
        // [GIVEN] The Guid Field (unidirectional) is not changed
        Commit();

        // [WHEN] Transfer the fields the second time
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the second transfer to succeed');
        // [THEN] The flag indicates that fields have not been modified
        Assert.IsFalse(IntegrationRecordSynch.GetWasModified(), 'Expected the second transfer to set the any field modified flag to false');
        // [THEN] The flag indicates that bidirectional fields have not been modified
        Assert.IsFalse(IntegrationRecordSynch.GetWasBidirectionalFieldModified(), 'Expected the second transfer to set the bidirectional field modified flag to false');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyModifiedFlagsAfterFieldsTransferWithChangedBidirectionalField()
    var
        SourceComparisonType: Record "Comparison Type";
        DestinationComparisonType: Record "Comparison Type";
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceTableRecRef: RecordRef;
        DestinationTableRecRef: RecordRef;
    begin
        // [SCENARIO] Transfer fields with the changed bidirectional field
        Initialize();

        // [GIVEN] Source row
        CreateComparisonTypeRow(SourceComparisonType);
        SourceTableRecRef.GetTable(SourceComparisonType);
        // [GIVEN] Destination row
        DestinationComparisonType."Key" := SourceComparisonType."Key" + 1;
        DestinationComparisonType.Insert();
        DestinationTableRecRef.GetTable(DestinationComparisonType);
        // [GIVEN] Bidirectional mapping for the Guid Field
        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, false);
        TempIntegrationFieldMapping.SetRange("Source Field No.", SourceComparisonType.FieldNo("GUID Field"));
        TempIntegrationFieldMapping.ModifyAll(Bidirectional, true);
        TempIntegrationFieldMapping.Reset();
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        // [GIVEN] Destination row has not been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Commit();

        // [WHEN] Transfer the fields the first time
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the first transfer to succeed');
        // [THEN] The flag indicates that fields have been modified
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified(), 'Expected the first transfer to set the any field modified flag to true');
        // [THEN] The flag indicates that bidirectional fields have been modified
        Assert.IsTrue(IntegrationRecordSynch.GetWasBidirectionalFieldModified(), 'Expected the first transfer to set the bidirectional field modified flag to true');

        // [GIVEN] Destination row has already been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, true);
        // [GIVEN] The Guid Field (bidirectional) is changed
        DestinationTableRecRef.Find();
        DestinationTableRecRef.Field(SourceComparisonType.FieldNo("Guid Field")).Value := CreateGuid();
        DestinationTableRecRef.Modify();
        Commit();

        // [WHEN] Transfer the fields the second time
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the second transfer to succeed');
        // [THEN] The flag indicates that fields have been modified
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified(), 'Expected the second transfer to set the any field modified flag to true');
        // [THEN] The flag indicates that bidirectional fields have been modified
        Assert.IsTrue(IntegrationRecordSynch.GetWasBidirectionalFieldModified(), 'Expected the second transfer to set the bidirectional field modified flag to true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyModifiedFlagsAfterFieldsTransferWithUnchangedBidirectionalField()
    var
        SourceComparisonType: Record "Comparison Type";
        DestinationComparisonType: Record "Comparison Type";
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceTableRecRef: RecordRef;
        DestinationTableRecRef: RecordRef;
    begin
        // [SCENARIO] Transfer fields with the unchanged bidirectional field
        Initialize();

        // [GIVEN] Source row
        CreateComparisonTypeRow(SourceComparisonType);
        SourceTableRecRef.GetTable(SourceComparisonType);
        // [GIVEN] Destination row
        DestinationComparisonType."Key" := SourceComparisonType."Key" + 1;
        DestinationComparisonType.Insert();
        DestinationTableRecRef.GetTable(DestinationComparisonType);
        // [GIVEN] Bidirectional mapping for the Guid Field
        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, false);
        TempIntegrationFieldMapping.SetRange("Source Field No.", SourceComparisonType.FieldNo("GUID Field"));
        TempIntegrationFieldMapping.ModifyAll(Bidirectional, true);
        TempIntegrationFieldMapping.Reset();
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        // [GIVEN] Destination row has not been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Commit();

        // [WHEN] Transfer the fields the first time
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the first transfer to succeed');
        // [THEN] The flag indicates that fields have been modified
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified(), 'Expected the first transfer to set the any field modified flag to true');
        // [THEN] The flag indicates that bidirectional fields have been modified
        Assert.IsTrue(IntegrationRecordSynch.GetWasBidirectionalFieldModified(), 'Expected the first transfer to set the bidirectional field modified flag to true');

        // [GIVEN] Destination row has already been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, true);
        // [GIVEN] The Guid Field (bidirectional) is not changed
        Commit();

        // [WHEN] Transfer the fields the second time
        Assert.IsTrue(IntegrationRecordSynch.Run(), 'Expected the second transfer to succeed');
        // [THEN] The flag indicates that fields have not been modified
        Assert.IsFalse(IntegrationRecordSynch.GetWasModified(), 'Expected the second transfer to set the any field modified flag to false');
        // [THEN] The flag indicates that bidirectional fields have not been modified
        Assert.IsFalse(IntegrationRecordSynch.GetWasBidirectionalFieldModified(), 'Expected the second transfer to set the bidirectional modified flag to false');
    end;

    local procedure Initialize()
    var
        ComparisonType: Record "Comparison Type";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        ComparisonType.DeleteAll();
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        JobQueueEntry.ModifyAll(Status, JobQueueEntry.Status::"On Hold", false);
    end;

    local procedure CreateComparisonTypeRow(var ComparisonType: Record "Comparison Type")
    var
        OutStream: OutStream;
        LastKey: Integer;
    begin
        if ComparisonType.FindLast() then
            LastKey := ComparisonType."Key";
        ComparisonType.Init();
        ComparisonType.Key := LastKey + 1;
        ComparisonType."Big Integer Field" := 10;
        ComparisonType."Boolean Field" := true;
        ComparisonType."Code Field" := 'CODE';
        ComparisonType."Date Field" := Today();
        Evaluate(ComparisonType."Date Formula Field", '<1Y>');
        ComparisonType."Date / Time Field" := CurrentDateTime();
        ComparisonType."Decimal Field" := 10.1;
        ComparisonType."Duration Field" := CurrentDateTime() - CreateDateTime(20000101D, 080000T);
        ComparisonType."Integer Field" := 10;
        ComparisonType."Option Field" := 3;
        ComparisonType."Text Field" := 'This is text';
        ComparisonType."Time Field" := Time();
        ComparisonType."Blob Field".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.Write('Long text in blob');
        ComparisonType."GUID Field" := CreateGuid();
        ComparisonType.Insert();
        ComparisonType."Record ID Field" := ComparisonType.RecordId();
        ComparisonType.Modify();
    end;

    local procedure CreateComparisonTypeRowTempIntegrationFieldMapping(var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary; IncludePrimaryKeyDefault: Boolean)
    var
        TempComparisonType: Record "Comparison Type" temporary;
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, Database::"Comparison Type");
        Field.SetFilter("No.", '<>%1&<>%2&<>%3&<>%4&<>%5&<>%6',
                            1, // Ignore the key
                            Field.FieldNo(SystemId),
                            Field.FieldNo(SystemCreatedAt),
                            Field.FieldNo(SystemCreatedBy),
                            Field.FieldNo(SystemModifiedAt),
                            Field.FieldNo(SystemModifiedBy));
        Field.FindSet();

        if IncludePrimaryKeyDefault then begin
            TempIntegrationFieldMapping.Init();
            TempIntegrationFieldMapping."No." := TempComparisonType.FieldNo("Key");
            TempIntegrationFieldMapping."Integration Table Mapping Name" := Field.TableName;
            TempIntegrationFieldMapping."Destination Field No." := TempIntegrationFieldMapping."No.";
            TempIntegrationFieldMapping."Validate Destination Field" := false;
            TempIntegrationFieldMapping."Constant Value" := '';
            TempIntegrationFieldMapping."Not Null" := false;
            TempIntegrationFieldMapping.Bidirectional := false;
            TempIntegrationFieldMapping.Insert();
        end;

        repeat
            TempIntegrationFieldMapping.Init();
            TempIntegrationFieldMapping."No." := Field."No.";
            TempIntegrationFieldMapping."Integration Table Mapping Name" := Field.TableName;
            TempIntegrationFieldMapping."Source Field No." := TempIntegrationFieldMapping."No.";
            TempIntegrationFieldMapping."Destination Field No." := TempIntegrationFieldMapping."No.";
            TempIntegrationFieldMapping."Validate Destination Field" := false;
            TempIntegrationFieldMapping."Constant Value" := '';
            TempIntegrationFieldMapping."Not Null" := false;
            TempIntegrationFieldMapping.Bidirectional := false;
            TempIntegrationFieldMapping.Insert();
        until Field.Next() = 0;
    end;

    local procedure PrepareSourceRowAndDestinationRefs(var SourceTableRecRef: RecordRef; var DestinationTableRecRef: RecordRef)
    begin
        CreateFilledComparisonTypeRef(SourceTableRecRef);
        CreateEmptyComparisonTypeRef(DestinationTableRecRef);
    end;

    local procedure CreateFilledComparisonTypeRef(var RecRef: RecordRef)
    var
        ComparisonType: Record "Comparison Type";
    begin
        CreateComparisonTypeRow(ComparisonType);
        RecRef.GetTable(ComparisonType);
    end;

    local procedure CreateEmptyComparisonTypeRef(var RecRef: RecordRef)
    var
        ComparisonType: Record "Comparison Type";
    begin
        ComparisonType.Reset();
        ComparisonType.Init();
        RecRef.GetTable(ComparisonType);
    end;

    local procedure ValidateComparisonTypeRow(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        "Field": Record "Field";
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
    begin
        // Validate primary key is different
        Assert.IsFalse(SourceRecordRef.Field(1).Value = DestinationRecordRef.Field(1).Value, 'Expected the primary keys to differ');

        // Validate fields are equal;
        Field.SetRange(TableNo, DATABASE::"Comparison Type");
        Field.SetFilter("No.", '<>%1&<>%2&<>%3&<>%4&<>%5&<>%6',
                            1, // Ignore the key
                            Field.FieldNo(SystemId),
                            Field.FieldNo(SystemCreatedAt),
                            Field.FieldNo(SystemCreatedBy),
                            Field.FieldNo(SystemModifiedAt),
                            Field.FieldNo(SystemModifiedBy));
        Field.FindSet();

        repeat
            SourceFieldRef := SourceRecordRef.Field(Field."No.");
            DestinationFieldRef := DestinationRecordRef.Field(Field."No.");
            if SourceFieldRef.Type <> FieldType::Blob then
                Assert.IsTrue(SourceFieldRef.Value = DestinationFieldRef.Value, 'Expected the two fields to match')
            else
                Assert.IsTrue(GetTextValue(SourceFieldRef) = GetTextValue(DestinationFieldRef), 'Expected the two fields to match')
        until Field.Next() = 0;
    end;

    local procedure GetTextValue(var FieldRef: FieldRef): Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        FieldValue: Text;
    begin
        if FieldRef.Type <> FieldType::Blob then
            exit(Format(FieldRef.Value));
        TempBlob.FromFieldRef(FieldRef);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(FieldValue);
        exit(FieldValue);
    end;
}

