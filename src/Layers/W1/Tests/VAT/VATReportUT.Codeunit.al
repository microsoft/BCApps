codeunit 134089 "VAT Report UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVATReport: Codeunit "Library - VAT Report";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Report] [UT]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadSubmissionMessageWhenVATDocAttachmentExist()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReport: TestPage "VAT Report";
        DocType: Enum "Attachment Document Type";
    begin
        // [SCENARIO 418697] Stan can download the submission message from the VAT Report with document attachment

        Initialize();
        LibraryVATReport.CreateVATReportConfigurationNo();
        CreateVATReturn(VATReportHeader);
        CreateBlankDocAttachmentForVATReport(VATReportHeader, DocType::"VAT Return Submission");
        VATReport.OpenEdit();
        VATReport.Filter.SetFilter("No.", VATReportHeader."No.");
        Assert.IsTrue(VATReport."Download Submission Message".Enabled(), 'Not possible to download submission message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadResponseMessageWhenVATDocAttachmentExist()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReport: TestPage "VAT Report";
        DocType: Enum "Attachment Document Type";
    begin
        // [SCENARIO 418697] Stan can download the response message from the VAT Report with document attachment

        Initialize();
        LibraryVATReport.CreateVATReportConfigurationNo();
        CreateVATReturn(VATReportHeader);
        CreateBlankDocAttachmentForVATReport(VATReportHeader, DocType::"VAT Return Response");
        VATReport.OpenEdit();
        VATReport.Filter.SetFilter("No.", VATReportHeader."No.");
        Assert.IsTrue(VATReport."Download Response Message".Enabled(), 'Not possible to download submission message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BiMonthlyDatesCalculationInVATReport()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // [SCENARIO 418697] Starting and Ending Date of the VAT report are correctly calculated in case of "Bi-Monthly" period type

        Initialize();
        CreateVATReturn(VATReportHeader);
        VATReportHeader.Validate("Period Year", 2022);
        VATReportHeader.Validate("Period Type", VATReportHeader."Period Type"::"Bi-Monthly");

        VATReportHeader.Validate("Period No.", 1);
        VATReportHeader.TestField("Start Date", 20220101D);
        VATReportHeader.TestField("End Date", 20220228D);
        VATReportHeader.Validate("Period No.", 6);
        VATReportHeader.TestField("Start Date", 20221101D);
        VATReportHeader.TestField("End Date", 20221231D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HalfYearDatesCalculationInVATReport()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // [SCENARIO 418697] Starting and Ending Date of the VAT report are correctly calculated in case of "Half-Year" period type

        Initialize();
        CreateVATReturn(VATReportHeader);
        VATReportHeader.Validate("Period Year", 2022);
        VATReportHeader.Validate("Period Type", VATReportHeader."Period Type"::"Half-Year");

        VATReportHeader.Validate("Period No.", 1);
        VATReportHeader.TestField("Start Date", 20220101D);
        VATReportHeader.TestField("End Date", 20220630D);
        VATReportHeader.Validate("Period No.", 2);
        VATReportHeader.TestField("Start Date", 20220701D);
        VATReportHeader.TestField("End Date", 20221231D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HalfMonthDatesCalculationInVATReport()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // [SCENARIO 418697] Starting and Ending Date of the VAT report are correctly calculated in case of "Half-Month" period type

        Initialize();
        CreateVATReturn(VATReportHeader);
        VATReportHeader.Validate("Period Year", 2022);
        VATReportHeader.Validate("Period Type", VATReportHeader."Period Type"::"Half-Month");

        VATReportHeader.Validate("Period No.", 1);
        VATReportHeader.TestField("Start Date", 20220101D);
        VATReportHeader.TestField("End Date", 20220115D);
        VATReportHeader.Validate("Period No.", 2);
        VATReportHeader.TestField("Start Date", 20220116D);
        VATReportHeader.TestField("End Date", 20220131D);
        VATReportHeader.Validate("Period No.", 3);
        VATReportHeader.TestField("Start Date", 20220201D);
        VATReportHeader.TestField("End Date", 20220215D);
        VATReportHeader.Validate("Period No.", 4);
        VATReportHeader.TestField("Start Date", 20220216D);
        VATReportHeader.TestField("End Date", 20220228D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WeeklyDatesCalculationInVATReport()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // [SCENARIO 418697] Starting and Ending Date of the VAT report are correctly calculated in case of "Weekly" period type

        Initialize();
        CreateVATReturn(VATReportHeader);
        VATReportHeader.Validate("Period Year", 2022);
        VATReportHeader.Validate("Period Type", VATReportHeader."Period Type"::Weekly);

        VATReportHeader.Validate("Period No.", 1);
        VATReportHeader.TestField("Start Date", 20220103D);
        VATReportHeader.TestField("End Date", 20220109D);
        VATReportHeader.Validate("Period No.", 2);
        VATReportHeader.TestField("Start Date", 20220110D);
        VATReportHeader.TestField("End Date", 20220116D);
    end;

    local procedure Initialize()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"VAT Report UT");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"VAT Report UT");
        VATReportSetup.Get();
        VATReportSetup.Validate("VAT Return No. Series", LibraryERM.CreateNoSeriesCode());
        VATReportSetup.Modify(true);
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"VAT Report UT");
    end;

    local procedure CreateVATReturn(var VATReportHeader: Record "VAT Report Header");
    begin
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader.Insert(true);
    end;

    local procedure CreateBlankDocAttachmentForVATReport(VATReportHeader: Record "VAT Report Header"; DocType: Enum "Attachment Document Type")
    var
        DocumentAttachment: Record "Document Attachment";
        Id: Integer;
    begin
        DocumentAttachment.SetRange("Table ID", Database::"VAT Report Header");
        DocumentAttachment.SetRange("No.", VATReportHeader."No.");
        if DocumentAttachment.FindLast() then;
        Id := DocumentAttachment.ID + 1;
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::"VAT Report Header";
        DocumentAttachment."No." := VATReportHeader."No.";
        DocumentAttachment.ID := Id;
        DocumentAttachment."Document Type" := DocType;
        DocumentAttachment.Insert();
    end;

}