codeunit 134056 "ERM VAT Report Header Line"
{
    // // [FEATURE] [VAT Report] [UT]

    SingleInstance = false;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        EmptyMsg: Label '%1 is not empty.';
        EditingAllowedErr: Label 'Editing is not allowed because the report is marked as %1.';
        CheckReopenedErr: Label 'This is not allowed because of the setup in the %1 window.';
        CheckRealesedErr: Label 'You must specify an original report for a report of type %1.';
        CheckEndDateErr: Label 'The end date cannot be earlier than the start date.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        CheckOnRenameErr: Label 'You cannot rename the report because it has been assigned a report number.';
        CheckOriginalRepNo1Err: Label 'You cannot specify an original report for a report of type %1.';
        CheckOriginalRepNo2Err: Label 'You cannot specify the same report as the reference report.';
        CheckOriginalRepNo3Err: Label 'Original Report No. must have a value in %1';
        DateErr: Label 'Start Date and End date should be the same as on the %1', Comment = '%1=Field Caption;';
        NoSeriesErr: Label 'No. Series not set correct';
        NoOnValidateErr: Label 'No. Series should be blank when manually inserting No.';
        InsertErr: Label 'Wrong no. series code';
        OnModifyErr: Label 'Start Date must have a value in %1';
        StartDateErr: Label 'Start Date must have a value in %1';
        EndDateErr: Label 'End Date must have a value in %1';
        VATReportTypeNotEqualErr: Label 'Setting VAT report header type failed.';

    [Test]
    [Scope('OnPrem')]
    procedure SetupVATReportHeader()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        NoSeries: Record "No. Series";
    begin
        Initialize();
        VATReportSetup.Get();
        NoSeries.FindFirst();
        VATReportSetup."No. Series" := NoSeries.Code;
        VATReportSetup.Modify();

        VATReportHdr.Init();
        VATReportHdr.Insert(true);
        Assert.AreEqual(NoSeries.Code, VATReportHdr."No. Series", InsertErr);
        TearDown(VATReportHdr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupVATReportHeaderDirectAssignment()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Init();
        VATReportHdr."No." := 'Test2';
        VATReportHdr.Insert(true);
        VATReportHdr.TestField("No.", 'Test2');

        TearDown(VATReportHdr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnModifyTrigger()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');

        asserterror VATReportHdr.Modify(true);
        Assert.ExpectedError(StrSubstNo(OnModifyErr, VATReportHdr.TableCaption()));

        VATReportHdr."Start Date" := Today;
        VATReportHdr."End Date" := Today;
        VATReportHdr.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInit()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        VATReportHdr.InitRecord();

        Assert.AreEqual(
          VATReportHdr."Start Date", WorkDate(), StrSubstNo(DateErr, VATReportHdr.FieldCaption("Original Report No.")));
        Assert.AreEqual(
          VATReportHdr."End Date", WorkDate(), StrSubstNo(DateErr, VATReportHdr.FieldCaption("Original Report No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoOnValidateTrigger()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        NoSeries: Record "No. Series";
    begin
        VATReportSetup.Get();
        NoSeries.SetRange("Manual Nos.", true);
        NoSeries.FindFirst();

        VATReportSetup."No. Series" := NoSeries.Code;
        VATReportSetup.Modify();

        VATReportHdr.Init();
        VATReportHdr.Validate("No.", 'Test6');
        Assert.AreEqual('', VATReportHdr."No. Series", NoOnValidateErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportConfigCodeOnValidate()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        VATReportHdr.Status := VATReportHdr.Status::Released;
        asserterror VATReportHdr.Validate("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code"::"VAT Transactions Report");
        Assert.ExpectedError(StrSubstNo(EditingAllowedErr, Format(VATReportHdr.Status)));

        VATReportHdr.Status := VATReportHdr.Status::Submitted;
        asserterror VATReportHdr.Validate("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code"::"VAT Transactions Report");
        Assert.ExpectedError(StrSubstNo(EditingAllowedErr, Format(VATReportHdr.Status)));

        VATReportHdr.Status := VATReportHdr.Status::Open;
        VATReportHdr.Validate("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code"::"VAT Transactions Report");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckEditAllowedNotAllowed()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        VATReportHdr.Status := VATReportHdr.Status::Released;
        asserterror VATReportHdr.CheckEditingAllowed();
        Assert.ExpectedError(StrSubstNo(EditingAllowedErr, Format(VATReportHdr.Status)));

        VATReportHdr.Status := VATReportHdr.Status::Submitted;
        asserterror VATReportHdr.CheckEditingAllowed();
        Assert.ExpectedError(StrSubstNo(EditingAllowedErr, Format(VATReportHdr.Status)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckEditAllowedAllowed()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        VATReportHdr.Status := VATReportHdr.Status::Open;
        VATReportHdr.CheckEditingAllowed();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckIfCanBeReopenedNotAllowed()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
    begin
        Initialize();
        VATReportSetup.Get();
        VATReportSetup."Modify Submitted Reports" := false;
        VATReportSetup.Modify();

        VATReportHdr.Get('Test');
        VATReportHdr.Status := VATReportHdr.Status::Submitted;

        asserterror VATReportHdr.CheckIfCanBeReopened(VATReportHdr);
        Assert.ExpectedError(StrSubstNo(CheckReopenedErr, VATReportSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckIfCanBeReopenedAllowed()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
    begin
        Initialize();
        VATReportSetup.Get();
        VATReportSetup."Modify Submitted Reports" := true;
        VATReportSetup.Modify();

        VATReportHdr.Get('Test');
        VATReportHdr.Status := VATReportHdr.Status::Submitted;

        VATReportHdr.CheckIfCanBeReopened(VATReportHdr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckIfCanBeReleasedNotAllowed()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        VATReportHdr.Status := VATReportHdr.Status::Open;
        VATReportHdr."VAT Report Type" := VATReportHdr."VAT Report Type"::Corrective;
        // It is assumed that: "Original Report No." = ''
        asserterror VATReportHdr.CheckIfCanBeReleased(VATReportHdr);
        Assert.ExpectedError(StrSubstNo(CheckRealesedErr, Format(VATReportHdr."VAT Report Type")));

        VATReportHdr."VAT Report Type" := VATReportHdr."VAT Report Type"::"Cancellation ";
        // It is assumed that: "Original Report No." = ''
        asserterror VATReportHdr.CheckIfCanBeReleased(VATReportHdr);
        Assert.ExpectedError(StrSubstNo(CheckRealesedErr, Format(VATReportHdr."VAT Report Type")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckIfCanBeReleasedAllowed()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        VATReportHdr.Status := VATReportHdr.Status::Open;
        VATReportHdr."VAT Report Type" := VATReportHdr."VAT Report Type"::Corrective;
        VATReportHdr."Original Report No." := 'x';
        VATReportHdr.CheckIfCanBeReleased(VATReportHdr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckIfCanBeSubmitted()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        VATReportHdr.Status := VATReportHdr.Status::Released;
        VATReportHdr."Tax Auth. Receipt No." := 'x';
        VATReportHdr."Tax Auth. Document No." := 'y';
        VATReportHdr.CheckIfCanBeSubmitted();

        VATReportHdr.Status := VATReportHdr.Status::Open;
        asserterror VATReportHdr.CheckIfCanBeSubmitted();
        Assert.ExpectedTestFieldError(VATReportHdr.FieldCaption(Status), Format(VATReportHdr.Status::Released));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckDates()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        // Test Start date
        VATReportHdr."Start Date" := 0D;
        asserterror VATReportHdr.CheckDates();
        Assert.ExpectedError(StrSubstNo(StartDateErr, VATReportHdr.TableCaption()));

        // Test End date
        VATReportHdr."Start Date" := Today;
        VATReportHdr."End Date" := 0D;
        asserterror VATReportHdr.CheckDates();
        Assert.ExpectedError(StrSubstNo(EndDateErr, VATReportHdr.TableCaption()));

        VATReportHdr."End Date" := Today;
        VATReportHdr.CheckDates();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckEndDate()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        VATReportHdr."Start Date" := Today;
        VATReportHdr."End Date" := Today;
        VATReportHdr.CheckEndDate();

        VATReportHdr."End Date" := Today - 1;
        asserterror VATReportHdr.CheckEndDate();
        Assert.ExpectedError(CheckEndDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTypeOnValidate()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
    begin
        Initialize();
        VATReportSetup.Get();
        VATReportSetup."Modify Submitted Reports" := true;
        VATReportSetup.Modify();

        VATReportHdr.Get('Test');
        VATReportHdr.Status := VATReportHdr.Status::Open;

        VATReportHdr.Validate("VAT Report Type", VATReportHdr."VAT Report Type"::Standard);
        Assert.AreEqual(VATReportHdr."VAT Report Type"::Standard, VATReportHdr."VAT Report Type", VATReportTypeNotEqualErr);

        VATReportHdr.Validate("VAT Report Type", VATReportHdr."VAT Report Type"::Corrective);
        Assert.AreEqual(VATReportHdr."VAT Report Type"::Corrective, VATReportHdr."VAT Report Type", VATReportTypeNotEqualErr);

        VATReportHdr.Validate("VAT Report Type", VATReportHdr."VAT Report Type"::"Cancellation ");
        Assert.AreEqual(VATReportHdr."VAT Report Type"::"Cancellation ", VATReportHdr."VAT Report Type", VATReportTypeNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnRenameTrigger()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        asserterror VATReportHdr.Rename('Test3');
        Assert.ExpectedError(CheckOnRenameErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOriginalReportNoOnValidate()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportHdr2: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        VATReportHdr."VAT Report Type" := VATReportHdr."VAT Report Type"::Standard;

        VATReportHdr.Validate("Original Report No.", '');

        //Original report number is not expected due to type Standart.
        asserterror VATReportHdr.Validate("Original Report No.", '1');
        Assert.ExpectedError(StrSubstNo(CheckOriginalRepNo1Err, VATReportHdr."VAT Report Type"));

        VATReportHdr."VAT Report Type" := VATReportHdr."VAT Report Type"::"Cancellation ";
        //Original report number is expected due to type Cancellation
        asserterror VATReportHdr.Validate("Original Report No.", '');
        Assert.ExpectedError(StrSubstNo(CheckOriginalRepNo3Err, VATReportHdr.TableCaption()));

        //Original report number cannot be the same as current report number.
        asserterror VATReportHdr.Validate("Original Report No.", VATReportHdr."No.");
        Assert.ExpectedError(CheckOriginalRepNo2Err);

        //Create an original report and check the validation.
        CreateVATReportHdr('Test4');
        VATReportHdr2.Get('Test4');
        VATReportHdr2.Validate(Status, VATReportHdr.Status::Submitted);
        VATReportHdr2.Modify(true);

        VATReportHdr.Validate("Original Report No.", 'Test4');

        Assert.AreEqual(
          VATReportHdr."Start Date", VATReportHdr2."Start Date", StrSubstNo(DateErr,
            VATReportHdr.FieldCaption("Original Report No.")));
        Assert.AreEqual(
          VATReportHdr."End Date", VATReportHdr2."End Date",
          StrSubstNo(DateErr, VATReportHdr.FieldCaption("Original Report No.")));

        TearDown(VATReportHdr2);
    end;

    [Test]
    [HandlerFunctions('VATReportListHandler')]
    [Scope('OnPrem')]
    procedure TestOriginalReportNoOnLookup()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportHdr2: Record "VAT Report Header";
        VATReport: TestPage "VAT Report";
    begin
        Initialize();
        CreateVATReportHdr('Test5');
        VATReportHdr2.Get('Test5');
        VATReportHdr2.Status := VATReportHdr2.Status::Submitted;
        VATReportHdr2.Modify();

        VATReportHdr.Get('Test');
        VATReportHdr."VAT Report Type" := VATReportHdr."VAT Report Type"::"Cancellation ";
        VATReportHdr.Modify();
        Commit();
        LibraryVariableStorage.Enqueue(VATReportHdr2."No.");
        VATReport.OpenNew();
        VATReport.GotoRecord(VATReportHdr);
        VATReport."Original Report No.".Lookup();
        VATReportHdr.Get(VATReport."No.".Value);
        VATReport.OK().Invoke();
        VATReportHdr.Find(); // Refresh record.
        VATReportHdr.TestField("Original Report No.", VATReportHdr2."No.");

        TearDown(VATReportHdr2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetNoSeriesCode()
    var
        VATReportSetup: Record "VAT Report Setup";
        NoSeries: Record "No. Series";
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportSetup.Get();
        NoSeries.FindFirst();
        VATReportSetup."No. Series" := NoSeries.Code;
        VATReportSetup.Modify();

        Assert.AreEqual(VATReportHdr.GetNoSeriesCode(), NoSeries.Code, NoSeriesErr);
        TearDown(VATReportHdr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnDeleteTrigger()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
        i: Integer;
    begin
        Initialize();
        VATReportHdr.Get('Test');
        VATReportHdr.Status := VATReportHdr.Status::Open;
        i := 0;
        repeat
            i += 1;
            VATReportLine."VAT Report No." := VATReportHdr."No.";
            VATReportLine."Line No." := GenerateLineNo(true, false) + 1;
            VATReportLine.Insert();
        until i = 2;

        VATReportLine.SetRange("VAT Report No.", VATReportHdr."No.");
        i := 0;
        VATReportLine.Find('-');
        repeat
            i += 1;
            VATReportLineRelation."VAT Report No." := VATReportLine."VAT Report No.";
            VATReportLineRelation."VAT Report Line No." := VATReportLine."Line No.";
            VATReportLineRelation."Line No." := GenerateLineNo(false, true) + 1;
            VATReportLineRelation.Insert();
        until VATReportLine.Next() = 0;

        VATReportHdr.Delete(true);
        Commit();
        VATReportHdr.SetRange("No.", 'Test');
        Assert.IsTrue(VATReportHdr.IsEmpty, StrSubstNo(EmptyMsg, VATReportLine.TableCaption()));
        Assert.IsTrue(VATReportLine.IsEmpty, StrSubstNo(EmptyMsg, VATReportLine.TableCaption()));
        VATReportLineRelation.SetRange("VAT Report No.", VATReportHdr."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyVATReportLine()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportSetup: Record "VAT Report Setup";
    begin
        Initialize();

        // Create VAT Report Header.
        VATReportHdr.Init();
        VATReportHdr.Insert();
        VATReportHdr.Status := VATReportHdr.Status::Released;
        VATReportHdr."VAT Report Type" := VATReportHdr."VAT Report Type"::Standard;
        VATReportHdr.Modify();

        // Create VAT Report Line.
        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportHdr."No.";
        VATReportLine."Line No." := GenerateLineNo(true, false);
        VATReportLine.Insert();

        // Modify VAT Report Setup.
        VATReportSetup.Get();
        VATReportSetup."Modify Submitted Reports" := false;
        VATReportSetup.Modify();

        // Modify VAT Report Line.
        VATReportLine."Document No." := VATReportLine."VAT Report No.";
        asserterror VATReportLine.Modify(true);

        // Verify Error Message.
        Assert.ExpectedError(StrSubstNo(EditingAllowedErr, VATReportHdr.Status::Released));

        // Cleanup.
        TearDown(VATReportHdr);
    end;

    local procedure Initialize()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        // Lazy Setup.
        if IsInitialized then
            exit;

        LibraryVariableStorage.Clear();
        IsInitialized := true;

        VATReportHdr.Init();
        VATReportHdr."No." := 'Test';
        VATReportHdr.Insert();

        Commit();
    end;

    local procedure GenerateLineNo(Line: Boolean; LineRelation: Boolean): Integer
    var
        VATReportLine: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        if Line then
            if VATReportLine.FindLast() then
                exit(VATReportLine."Line No.");
        if LineRelation then
            if VATReportLineRelation.FindLast() then
                exit(VATReportLineRelation."Line No.");
        exit(0);
    end;

    local procedure CreateVATReportHdr(No: Code[20])
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        VATReportHdr.Init();
        VATReportHdr."No." := No;
        VATReportHdr."Start Date" := Today + 1;
        VATReportHdr."End Date" := Today + 1;

        VATReportHdr.Insert(true);
    end;

    local procedure TearDown(VATReportHdr: Record "VAT Report Header")
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        if VATReportHdr."No." <> '' then
            VATReportHdr.Delete();

        VATReportSetup.Get();
        VATReportSetup."No. Series" := '';
        VATReportSetup."Modify Submitted Reports" := false;
        VATReportSetup.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATReportListHandler(var VATReportList: TestPage "VAT Report List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VATReportList.GotoKey(No);
        VATReportList.OK().Invoke();
    end;
}

