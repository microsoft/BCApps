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
        ReminderTextBeginning: array[2] of Record "Reminder Text";
        ReminderTextEnding: array[2] of Record "Reminder Text";
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        ReminderTestReport: Report "Reminder - Test";
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO 364318] All the lines of Reminder's beginning and Ending text should be printed in "Reminder - Test" Report
        Initialize();
        // [GIVEN] Reminder with 2 lines of beginning and 2 lines of ending texts
        CreateReminderHeader(ReminderHeader);

        LibraryERM.CreateReminderText(
          ReminderTextBeginning[1],
          ReminderHeader."Reminder Terms Code",
          ReminderHeader."Reminder Level",
          ReminderTextBeginning[1].Position::Beginning,
          LibraryUtility.GenerateGUID());
        LibraryERM.CreateReminderText(
          ReminderTextBeginning[2],
          ReminderHeader."Reminder Terms Code",
          ReminderHeader."Reminder Level",
          ReminderTextBeginning[2].Position::Beginning,
          LibraryUtility.GenerateGUID());

        LibraryERM.CreateReminderLine(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"G/L Account");

        LibraryERM.CreateReminderText(
          ReminderTextEnding[1],
          ReminderHeader."Reminder Terms Code",
          ReminderHeader."Reminder Level",
          ReminderTextEnding[1].Position::Ending,
          LibraryUtility.GenerateGUID());
        LibraryERM.CreateReminderText(
          ReminderTextEnding[2],
          ReminderHeader."Reminder Terms Code",
          ReminderHeader."Reminder Level",
          ReminderTextEnding[2].Position::Ending,
          LibraryUtility.GenerateGUID());

        ReminderHeader.InsertLines();

        // [WHEN] Printing "Reminder - Test" Report
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        ReminderTestReport.SetTableView(ReminderLine);
        ReminderTestReport.SaveAsExcel(LibraryReportValidation.GetFileName());

        // [THEN] Both beginning text lines are printed in column 2 of lines 23 and 24
        // [THEN] Both ending text lines are printed in column 2 of lines 28 and 29
        ValidateReminderTexts(ReminderTextBeginning, ReminderTextEnding);
    end;

    local procedure Initialize()
    var
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
    begin
        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;
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

    local procedure ValidateReminderTexts(ReminderTextBeginning: array[2] of Record "Reminder Text"; ReminderTextEnding: array[2] of Record "Reminder Text")
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

