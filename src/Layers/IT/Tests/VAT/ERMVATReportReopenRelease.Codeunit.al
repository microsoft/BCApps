codeunit 134058 "ERM VAT Report Reopen Release"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Report] [Release/Reopen] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVATUtils: Codeunit "Library - VAT Utils";
        StatusReleasedErr: Label 'Status should be Released';
        StatusOpenErr: Label 'Status should be Open';
        MissingSetupErr: Label 'This is not allowed because of the setup in the %1 window.', Comment = '%1 - page name';
        StatusSubmittedErr: Label 'Status should be sumbitted';

    [Test]
    [Scope('OnPrem')]
    procedure TestRelease()
    var
        VATReportHdr: Record "VAT Report Header";
        CompanyInformation: Record "Company Information";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        CreateVATReportHeaderAndLines(VATReportHdr);

        CompanyInformation.Get();
        CompanyInformation."Fiscal Code" := 'x';
        CompanyInformation.County := 'x';
        CompanyInformation."VAT Registration No." := LibraryVATUtils.GenerateVATRegistrationNumber();
        CompanyInformation."Industrial Classification" := '35.11.00';
        CompanyInformation.Modify();

        VATReportReleaseReopen.Release(VATReportHdr);

        Assert.AreEqual(VATReportHdr.Status::Released, VATReportHdr.Status, StatusReleasedErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReopen()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        CreateVATReportHeaderAndLines(VATReportHdr);
        VATReportHdr.Status := VATReportHdr.Status::Released;
        VATReportHdr.Modify();
        VATReportReleaseReopen.Reopen(VATReportHdr);

        Assert.AreEqual(VATReportHdr.Status::Open, VATReportHdr.Status, StatusOpenErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReopenNotAllowed()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        CreateVATReportHeaderAndLines(VATReportHdr);
        VATReportHdr.Status := VATReportHdr.Status::Submitted;
        VATReportHdr.Modify();

        VATReportSetup.Get();
        VATReportSetup."Modify Submitted Reports" := false;
        VATReportSetup.Modify();

        asserterror VATReportReleaseReopen.Reopen(VATReportHdr);
        Assert.ExpectedError(StrSubstNo(MissingSetupErr, VATReportSetup.TableCaption()));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubmit()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        CreateVATReportHeaderAndLines(VATReportHdr);

        VATReportHdr.Status := VATReportHdr.Status::Released;
        VATReportHdr."Tax Auth. Receipt No." := 'x';
        VATReportHdr."Tax Auth. Document No." := 'y';
        VATReportHdr.Modify();
        VATReportReleaseReopen.Submit(VATReportHdr);

        Assert.AreEqual(VATReportHdr.Status::Submitted, VATReportHdr.Status, StatusSubmittedErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubmitNotAllowed()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        CreateVATReportHeaderAndLines(VATReportHdr);
        asserterror VATReportReleaseReopen.Submit(VATReportHdr);
        Assert.ExpectedTestFieldError(VATReportHdr.FieldCaption(Status), Format(VATReportHdr.Status::Released));

        TearDown();
    end;

    local procedure CreateVATReportHeaderAndLines(var VATReportHdr: Record "VAT Report Header")
    var
        VatReportLine: Record "VAT Report Line";
        VATReportSetup: Record "VAT Report Setup";
        NoSeries: Record "No. Series";
    begin
        VATReportSetup.Get();
        NoSeries.Init();
        NoSeries.FindFirst();
        VATReportSetup."No. Series" := NoSeries.Code;
        VATReportSetup."Intermediary VAT Reg. No." := LibraryVATUtils.GenerateVATRegistrationNumber();
        VATReportSetup.Modify();

        VATReportHdr."No." := 'Test';
        VATReportHdr.Status := VATReportHdr.Status::Open;
        VATReportHdr."VAT Report Config. Code" := VATReportHdr."VAT Report Config. Code"::"VAT Transactions Report";
        VATReportHdr.Insert(true);

        VatReportLine.Init();
        VatReportLine."VAT Report No." := VATReportHdr."No.";
        VatReportLine."Line No." := 1;
        VatReportLine.Insert();
    end;

    local procedure TearDown()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportSetup: Record "VAT Report Setup";
        CompanyInformation: Record "Company Information";
    begin
        VATReportLine.SetRange("VAT Report No.", 'Test');
        VATReportLine.DeleteAll();

        VATReportHdr.SetRange("No.", 'Test');
        VATReportHdr.DeleteAll();

        VATReportSetup.Get();
        VATReportSetup."No. Series" := '';
        VATReportSetup.Modify();

        CompanyInformation.Get();
        CompanyInformation."Fiscal Code" := '';
        CompanyInformation.County := '';
        CompanyInformation.Modify();
    end;
}

