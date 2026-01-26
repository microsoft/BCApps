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
        EditingAllowedError: Label 'Editing is not allowed because the report is marked as %1.';
        CheckReopenedError: Label 'This is not allowed because of the setup in the %1 window.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        CheckOnRenameError: Label 'You cannot rename the report because it has been assigned a report number.';
        NoSeriesError: Label 'No. Series not set correct';
        NoOnValidateError: Label 'No. Series should be blank when manually inserting No.';
        InsertError: Label 'Wrong no. series code';
        OnModifyError: Label 'Start Date must have a value in %1';
        StartDateError: Label 'Start Date must have a value in %1';
        EndDateError: Label 'End Date must have a value in %1';

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
        Assert.AreEqual(NoSeries.Code, VATReportHdr."No. Series", InsertError);
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
        Assert.ExpectedError(StrSubstNo(OnModifyError, VATReportHdr.TableCaption()));

        VATReportHdr."Start Date" := Today;
        VATReportHdr."End Date" := Today;
        VATReportHdr.Modify(true);
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
        Assert.AreEqual('', VATReportHdr."No. Series", NoOnValidateError)
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
        asserterror VATReportHdr.Validate("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code"::VIES);
        Assert.ExpectedError(StrSubstNo(EditingAllowedError, Format(VATReportHdr.Status)));

        VATReportHdr.Status := VATReportHdr.Status::Submitted;
        asserterror VATReportHdr.Validate("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code"::VIES);
        Assert.ExpectedError(StrSubstNo(EditingAllowedError, Format(VATReportHdr.Status)));

        VATReportHdr.Status := VATReportHdr.Status::Open;
        VATReportHdr.Validate("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code"::VIES);
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
        Assert.ExpectedError(StrSubstNo(EditingAllowedError, Format(VATReportHdr.Status)));

        VATReportHdr.Status := VATReportHdr.Status::Submitted;
        asserterror VATReportHdr.CheckEditingAllowed();
        Assert.ExpectedError(StrSubstNo(EditingAllowedError, Format(VATReportHdr.Status)));
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
        Assert.ExpectedError(StrSubstNo(CheckReopenedError, VATReportSetup.TableCaption()));
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
    procedure TestCheckDates()
    var
        VATReportHdr: Record "VAT Report Header";
    begin
        Initialize();
        VATReportHdr.Get('Test');
        // Test Start date
        VATReportHdr."Start Date" := 0D;
        asserterror VATReportHdr.CheckDates();
        Assert.ExpectedError(StrSubstNo(StartDateError, VATReportHdr.TableCaption()));

        // Test End date
        VATReportHdr."Start Date" := Today;
        VATReportHdr."End Date" := 0D;
        asserterror VATReportHdr.CheckDates();
        Assert.ExpectedError(StrSubstNo(EndDateError, VATReportHdr.TableCaption()));

        VATReportHdr."End Date" := Today;
        VATReportHdr.CheckDates();
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
        Assert.ExpectedError(CheckOnRenameError);
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

        Assert.AreEqual(VATReportHdr.GetNoSeriesCode(), NoSeries.Code, NoSeriesError);
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
