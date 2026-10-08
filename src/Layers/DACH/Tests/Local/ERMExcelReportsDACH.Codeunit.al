codeunit 142082 "ERM Excel Reports DACH"
{
    // // [FEATURE] [Report]
    // Test and verify time expensive ERM reports with Library Report Validation

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        WrongCellValueTxt: Label 'Wrong cell value';

    [Test]
    [Scope('OnPrem')]
    procedure ReminderTestReportTestEndingAndBeginningTexts()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderAttachmentTextLineBeginning: array[2] of Record "Reminder Attachment Text Line";
        ReminderAttachmentTextLineEnding: array[2] of Record "Reminder Attachment Text Line";
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        ReminderLevel: Record "Reminder Level";
        ReminderTestReport: Report "Reminder - Test";
        Language: Codeunit Language;
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO 364318] All the lines of Reminder's beginning and Ending text should be printed in "Reminder - Test" Report
        Initialize();
        // [GIVEN] Reminder with 2 lines of beginning and 2 lines of ending texts
        CreateReminderHeader(ReminderHeader);
        ReminderLevel.Get(ReminderHeader."Reminder Terms Code", ReminderHeader."Reminder Level");
        LibraryERM.CreateReminderAttachmentText(ReminderAttachmentText, ReminderLevel, Language.GetUserLanguageCode());

        LibraryERM.CreateReminderAttachmentTextLine(
          ReminderAttachmentTextLineBeginning[1],
          ReminderAttachmentText,
          ReminderAttachmentTextLineBeginning[1].Position::"Beginning Line",
          LibraryUtility.GenerateGUID());
        LibraryERM.CreateReminderAttachmentTextLine(
          ReminderAttachmentTextLineBeginning[2],
          ReminderAttachmentText,
          ReminderAttachmentTextLineBeginning[2].Position::"Beginning Line",
          LibraryUtility.GenerateGUID());

        LibraryERM.CreateReminderLine(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"G/L Account");

        LibraryERM.CreateReminderAttachmentTextLine(
          ReminderAttachmentTextLineEnding[1],
          ReminderAttachmentText,
          ReminderAttachmentTextLineEnding[1].Position::"Ending Line",
          LibraryUtility.GenerateGUID());
        LibraryERM.CreateReminderAttachmentTextLine(
          ReminderAttachmentTextLineEnding[2],
          ReminderAttachmentText,
          ReminderAttachmentTextLineEnding[2].Position::"Ending Line",
          LibraryUtility.GenerateGUID());

        ReminderHeader.InsertLines();

        // [WHEN] Printing "Reminder - Test" Report
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        ReminderTestReport.SetTableView(ReminderLine);
        ReminderTestReport.SaveAsExcel(LibraryReportValidation.GetFileName());

        // [THEN] Both beginning text lines are printed in column 2 of lines 23 and 24
        // [THEN] Both ending text lines are printed in column 2 of lines 28 and 29
        ValidateReminderTexts(ReminderAttachmentTextLineBeginning, ReminderAttachmentTextLineEnding);
    end;

    local procedure Initialize()
    begin
        Commit();
        Clear(LibraryReportValidation);
    end;

    local procedure CreateReminderHeader(var ReminderHeader: Record "Reminder Header")
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        LibraryERM.CreateReminderTerms(ReminderTerms);
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);

        ReminderHeader."Reminder Terms Code" := ReminderTerms.Code;
        ReminderHeader."Reminder Level" := ReminderLevel."No.";

        CustomerPostingGroup.Code :=
          LibraryUtility.GenerateRandomCode(CustomerPostingGroup.FieldNo(Code), DATABASE::"Customer Posting Group");
        CustomerPostingGroup."Receivables Account" := LibraryERM.CreateGLAccountNo();
        CustomerPostingGroup.Insert(true);

        ReminderHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        ReminderHeader.Modify();
    end;

    local procedure ValidateReminderTexts(ReminderTextBeginning: array[2] of Record "Reminder Attachment Text Line"; ReminderTextEnding: array[2] of Record "Reminder Attachment Text Line")
    var
        ExcelSheetNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        ExcelSheetNo := LibraryReportValidation.CountWorksheets();
        Assert.AreEqual(
          ReminderTextBeginning[1].Text,
          LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(ExcelSheetNo, 23, 2),
          WrongCellValueTxt + ' ' + Format(23) + ';' + Format(2));
        Assert.AreEqual(
          ReminderTextBeginning[2].Text,
          LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(ExcelSheetNo, 24, 2),
          WrongCellValueTxt + ' ' + Format(24) + ';' + Format(2));

        Assert.AreEqual(
          ReminderTextEnding[1].Text,
          LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(ExcelSheetNo, 28, 2),
          WrongCellValueTxt + ' ' + Format(28) + ';' + Format(2));
        Assert.AreEqual(
          ReminderTextEnding[2].Text,
          LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(ExcelSheetNo, 29, 2),
          WrongCellValueTxt + ' ' + Format(29) + ';' + Format(2));
    end;
}
