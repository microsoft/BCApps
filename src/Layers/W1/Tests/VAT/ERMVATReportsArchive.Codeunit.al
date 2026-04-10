codeunit 134094 "ERM VAT Reports Archive"
{
    Permissions = TableData "VAT Report Archive" = rimd;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Report] [Archive]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure TestArchiveSubmissionMessage()
    var
        VATReportArchive: Record "VAT Report Archive";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ReportText: Text;
        BigString: BigText;
        VATReportNo: Code[20];
    begin
        // [SCENARIO] When VAT Report is submitted to Tax Authority's service, the submission message is archived

        // [GIVEN] The report message with specific report type and report No
        ReportText := LibraryUtility.GenerateRandomText(100);
        BigString.AddText(ReportText);
        TempBlob.CreateOutStream(OutStream);
        BigString.Write(OutStream);

        VATReportNo := CopyStr(LibraryUtility.GenerateRandomText(20), 1, 20);

        // [WHEN] The message is archived
        LibraryLowerPermissions.SetO365Basic();
        VATReportArchive.ArchiveSubmissionMessage(VATReportArchive."VAT Report Type"::"VAT Return".AsInteger(), VATReportNo, TempBlob);

        // [THEN] User can open it from VAT Report List page
        VATReportArchive.Get(VATReportArchive."VAT Report Type"::"VAT Return", VATReportNo);
        Assert.IsTrue(VATReportArchive."Submission Message BLOB".HasValue, 'The VAT Report submission archive is empty.');
        Assert.AreEqual(VATReportArchive."VAT Report No.", VATReportNo, '');
        Assert.AreEqual(VATReportArchive."VAT Report Type", VATReportArchive."VAT Report Type"::"VAT Return", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestArchiveResponseMessage()
    var
        VATReportArchive: Record "VAT Report Archive";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ReportText: Text;
        BigString: BigText;
        VATReportNo: Code[20];
    begin
        // [SCENARIO] When VAT Report response is received from Tax Authority's service, the response message is archived

        // [GIVEN] The response report message with specific report type and report No
        ReportText := LibraryUtility.GenerateRandomText(100);
        BigString.AddText(ReportText);
        TempBlob.CreateOutStream(OutStream);
        BigString.Write(OutStream);

        VATReportNo := CopyStr(LibraryUtility.GenerateRandomText(20), 1, 20);

        // [WHEN] The message is archived
        LibraryLowerPermissions.SetO365Basic();
        VATReportArchive.ArchiveSubmissionMessage(VATReportArchive."VAT Report Type"::"VAT Return".AsInteger(), VATReportNo, TempBlob);
        VATReportArchive.ArchiveResponseMessage(VATReportArchive."VAT Report Type"::"VAT Return".AsInteger(), VATReportNo, TempBlob);

        // [THEN] User can open it
        VATReportArchive.Get(VATReportArchive."VAT Report Type"::"VAT Return", VATReportNo);
        Assert.IsTrue(VATReportArchive."Response Message BLOB".HasValue, 'The VAT Report response archive is empty.');
    end;
}

