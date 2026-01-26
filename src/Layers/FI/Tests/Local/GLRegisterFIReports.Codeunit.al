codeunit 144019 "G/L Register FI Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        CurrentRowErr: Label 'Current row does not have Field ''%1'' = <%2>.', Comment = '%1 is the name of the DataSet field, and %2 is the value of that field.';
        ReportErr: Label '%1 must be %2 in Report.';

    [Test]
    [HandlerFunctions('RHGLRegisterFIReport')]
    [Scope('OnPrem')]
    procedure GLRegisterFI()
    var
        GLEntry: Record "G/L Entry";
    begin
        // Verify GL Register FI Report.

        // Setup: Create and post General Journal Line With Random values.
        CreateAndPostGenLine();
        GLEntry.FindLast();

        // Exercise. Save GL Register FI Report.
        GLRegisterFIReport(GLEntry."Posting Date", GLEntry."No. Series", GLEntry."Document No.");

        // Verify: Verify GL Register FI Report.
        VerifyGLRegisterFIReport(GLEntry);
    end;

    local procedure CreateAndPostGenLine()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GLRegisterFIReport(PostingDate: Date; NoSeries: Code[20]; DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        GLRegisterFIReport: Report "G/L Register FI";
    begin
        Clear(GLRegisterFIReport);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("No. Series", NoSeries);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLRegisterFIReport.SetTableView(GLEntry);
        GLRegisterFIReport.Run();
    end;

    local procedure VerifyGLRegisterFIReport(GLEntry: Record "G/L Entry")
    var
        XmlPostingDate: Variant;
    begin
        LibraryReportDataset.LoadDataSetFile();
        if LibraryReportDataset.GetNextRow() then begin
            LibraryReportDataset.FindCurrentRowValue('PostingDate_GLEntry', XmlPostingDate);
            Assert.AreEqual(GLEntry."Posting Date", EvaluateXmlDate(XmlPostingDate),
              StrSubstNo(CurrentRowErr, 'PostingDate_GLEntry', GLEntry."Posting Date"));
            LibraryReportDataset.AssertCurrentRowValueEquals('NoSeries_GLEntry', GLEntry."No. Series");
            LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_GLEntry', GLEntry."Document No.")
        end else
            Error(ReportErr, GLEntry.FieldCaption("Document No."), GLEntry."Document No.");
    end;

    local procedure EvaluateXmlDate(DateText: Text): Date
    var
        DotNetDateTime: DotNet DateTime;
        XmlDateTimeSerializationMode: DotNet XmlDateTimeSerializationMode;
        XMLConvert: DotNet XmlConvert;
    begin
        DotNetDateTime := XMLConvert.ToDateTime(DateText, XmlDateTimeSerializationMode.Unspecified);
        exit(DMY2Date(DotNetDateTime.Day, DotNetDateTime.Month, DotNetDateTime.Year));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGLRegisterFIReport(var GLRegisterReport: TestRequestPage "G/L Register FI")
    begin
        GLRegisterReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;
}

