codeunit 142067 "UT COD VATSTAT"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;
        SameValueMsg: Label 'Value must be same.';

    [Test]
    [HandlerFunctions('GLVATReconciliationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintGLVATReconciliationDocumentPrint()
    var
        VATStatementName: Record "VAT Statement Name";
        ReportSelections: Record "Report Selections";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // Purpose of the test is to validate Method PrintGLVATReconciliation for Codeunit 229 - Document-Print.
        // Setup.
        CreateReportSelections(ReportSelections.Usage::"Sales VAT Acc. Proof", REPORT::"G/L - VAT Reconciliation");

        // Exercise and Verify: Print G/L - VAT Reconciliation. Added Request Page Handler - GLVATReconciliationRequestPageHandler.
        DocumentPrint.PrintSalesVATAdvNotAccProof(VATStatementName);
    end;

    [Test]
    [HandlerFunctions('VATStatementScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintVATStatementScheduleDocumentPrint()
    var
        VATStatementName: Record "VAT Statement Name";
        ReportSelections: Record "Report Selections";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // Purpose of the test is to validate Method PrintVATStatementSchedule for Codeunit 229 - Document-Print.
        // Setup.
        CreateReportSelections(ReportSelections.Usage::"VAT Statement Schedule", REPORT::"VAT Statement Schedule");

        // Exercise and Verify: Print VAT Statement Schedule. Added Request Page Handler - VATStatementScheduleRequestPageHandler.
        DocumentPrint.PrintVATStatementSchedule(VATStatementName);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TaxOfficeFormatAddress()
    var
        CompanyInformation: Record "Company Information";
        FormatAddress: Codeunit "Format Address";
        AddrArray: array[8] of Text[100];
    begin
        // Purpose of the test is to validate Method TaxOffice for Codeunit 365 - Format Address.
        // Setup.
        CompanyInformation.Get();

        // Exercise.
        FormatAddress.TaxOffice(AddrArray, CompanyInformation);

        // Verify.
        Assert.AreEqual(AddrArray[1], CompanyInformation."Tax Office Name", SameValueMsg);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateVATStatementWithoutTemplateError()
    var
        VATStatementTemplate: Record "VAT Statement Template";
        UpdateVATAT: Codeunit "Update VAT-AT";
    begin
        // Purpose of the test is to validate Method UpdateVATStatementTemplate for Codeunit 11110 - Update VAT-AT.
        // Setup.
        VATStatementTemplate.DeleteAll();

        // Exercise.
        asserterror UpdateVATAT.UpdateVATStatementTemplate(VATStatementTemplate.Name, VATStatementTemplate.Description, '');

        // Verify: Verify Expected Code, Actual error message: No VAT Statement Template has been created or updated.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateVATStatementWithTemplateError()
    var
        VATStatementTemplate: Record "VAT Statement Template";
        UpdateVATAT: Codeunit "Update VAT-AT";
    begin
        // Purpose of the test is to validate Method UpdateVATStatementTemplate for Codeunit 11110 - Update VAT-AT.
        // Setup.
        CreateVATStatementTemplate(VATStatementTemplate);

        // Exercise.
        asserterror UpdateVATAT.UpdateVATStatementTemplate(VATStatementTemplate.Name, VATStatementTemplate.Description, '');

        // Verify: Verify Expected Code, Actual error message: No VAT Statement Template has been created or updated.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVATStatementNameAndLine()
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        UpdateVATAT: Codeunit "Update VAT-AT";
    begin
        // Purpose of the test is to validate Method Update for Codeunit 11110 - Update VAT-AT.

        // Setup: Transaction Model is AutoCommit required as Commit is called explicitly from Function Update in Codeunit 11110 - Update VAT-AT.
        CreateVATStatementTemplate(VATStatementTemplate);

        // Exercise.
        UpdateVATAT.Update(VATStatementTemplate.Name, VATStatementTemplate.Description, '');

        // Verify: Verify new created VAT Statement Name and VAT Statement Line.
        VATStatementName.SetRange("Statement Template Name", VATStatementTemplate.Name);
        Assert.AreEqual(1, VATStatementName.Count, SameValueMsg);  // Number of Records in VAT Statement Name is equal to 1.
        VerifyVATStatementLine(VATStatementTemplate.Name);
    end;

    local procedure CreateReportSelections(Usage: Enum "Report Selection Usage"; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := LibraryUTUtility.GetNewCode10();
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;

    local procedure CreateVATStatementTemplate(var VATStatementTemplate: Record "VAT Statement Template")
    begin
        VATStatementTemplate.Name := LibraryUTUtility.GetNewCode10();
        VATStatementTemplate.Insert();
    end;

    local procedure VerifyVATStatementLine(StatementTemplateName: Code[10])
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.SetRange("Statement Template Name", StatementTemplateName);
        VATStatementLine.FindFirst();
        VATStatementLine.TestField(Type);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVATReconciliationRequestPageHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementScheduleRequestPageHandler(var VATStatementSchedule: TestRequestPage "VAT Statement Schedule")
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

