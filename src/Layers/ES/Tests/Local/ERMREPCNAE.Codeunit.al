codeunit 144036 "ERM REP CNAE"
{
    // Test for feature - CNAE - Reports.
    //  1. Verify CNAE Description on Company Information Card, Update Company Information - CNAE Description.
    //  2. Verify Company Information - Name and Address. Create Normalized Account and Run Report - 10717 Normalized Account Schedule.
    //
    // Covers Test Cases for WI - 351133.
    // -----------------------------------------------------------------------------
    // Test Function Name                                                   TFS ID
    // -----------------------------------------------------------------------------
    // NormalizedAccountScheduleReportForUpdatedCompanyInfo                 156907
    // CNAEDescriptionOnCompanyInformationCard                              151552

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure CNAEDescriptionOnCompanyInformationCard()
    var
        CompanyInformation: TestPage "Company Information";
        CNAEDescription: Text;
        OldCNAEDescription: Text;
    begin
        // Verify CNAE Description on Company Information card, Update Company Information - CNAE Description.

        // Setup: Update Company Information - CNAE Description to length - 80.
        CNAEDescription := GenerateRandomCode(80);  // Number of Digit - 80.

        // Exercise.
        OldCNAEDescription := UpdateCompanyInformationCNAEDescription(CNAEDescription);

        // Verify: Verify CNAE Description with CNAE Description field on Company Information Card.
        CompanyInformation.OpenEdit();
        CompanyInformation."CNAE Description".AssertEquals(CNAEDescription);
        CompanyInformation.Close();

        // TearDown.
        UpdateCompanyInformationCNAEDescription(OldCNAEDescription);
    end;

    local procedure GenerateRandomCode(NumberOfDigit: Integer) ElectronicCode: Text[1024]
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfDigit do
            ElectronicCode := InsStr(ElectronicCode, Format(LibraryRandom.RandInt(9)), Counter);  // Random value of 1 digit required.
    end;

    local procedure UpdateCompanyInformationCNAEDescription(CNAEDescription: Text) OldCompanyInformationCNAEDescription: Text
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        OldCompanyInformationCNAEDescription := CompanyInformation."CNAE Description";
        CompanyInformation.Validate("CNAE Description", CNAEDescription);
        CompanyInformation.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NormalizedAccountScheduleRequestPageHandler(var NormalizedAccountSchedule: TestRequestPage "Normalized Account Schedule")
    begin
        NormalizedAccountSchedule."Acc. Schedule Line".SetFilter("Date Filter", Format(WorkDate()));
        NormalizedAccountSchedule.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
