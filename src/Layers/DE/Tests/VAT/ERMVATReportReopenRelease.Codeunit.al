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
        StatusOpenErr: Label 'Status should be Open';
        MissingSetupErr: Label 'This is not allowed because of the setup in the %1 window.', Comment = '%1 - page name';

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

    local procedure CreateVATReportHeaderAndLines(var VATReportHdr: Record "VAT Report Header")
    var
        VATReportLine: Record "VAT Report Line";
        VATReportSetup: Record "VAT Report Setup";
        NoSeries: Record "No. Series";
    begin
        VATReportSetup.Get();
        NoSeries.Init();
        NoSeries.FindFirst();
        VATReportSetup."No. Series" := NoSeries.Code;
        VATReportSetup.Modify();

        VATReportHdr."No." := 'Test';
        VATReportHdr.Status := VATReportHdr.Status::Open;
        VATReportHdr.Insert(true);

        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportHdr."No.";
        VATReportLine."Line No." := 1;
        VATReportLine.Insert();
    end;

    local procedure TearDown()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportLine.SetRange("VAT Report No.", 'Test');
        VATReportLine.DeleteAll();

        VATReportHdr.SetRange("No.", 'Test');
        VATReportHdr.DeleteAll();

        VATReportSetup.Get();
        VATReportSetup."No. Series" := '';
        VATReportSetup.Modify();
    end;
}


