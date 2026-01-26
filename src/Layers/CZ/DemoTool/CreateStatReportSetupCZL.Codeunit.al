codeunit 163533 "Create Stat. Report. Setup CZL"
{

    trigger OnRun()
    begin
        StatutoryReportingSetupCZL.Get();
        StatutoryReportingSetupCZL."VAT Statement Template Name" := CreateVATStatementTemplate.GetVATName();
        StatutoryReportingSetupCZL."VAT Statement Name" := CreateVATStatementName.GetVAT('XVAT19');
        StatutoryReportingSetupCZL."Company Type" := StatutoryReportingSetupCZL."Company Type"::Corporate;
        StatutoryReportingSetupCZL."Company Trade Name" := XCRONUSInternational;
        StatutoryReportingSetupCZL."Company Trade Name Appendix" := XAs;
        StatutoryReportingSetupCZL."VAT Control Report E-mail" := XTestEmail;
        StatutoryReportingSetupCZL."Data Box ID" := XABC123;
        StatutoryReportingSetupCZL."Simplified Tax Document Limit" := 10000;
        StatutoryReportingSetupCZL."VAT Statement Country Name" := XCzechRepublic;
        StatutoryReportingSetupCZL."Tax Payer Status" := StatutoryReportingSetupCZL."Tax Payer Status"::Payer;
        StatutoryReportingSetupCZL."VIES Number of Lines" := 20;
        StatutoryReportingSetupCZL.Validate("VIES Declaration Export No.", Xmlport::"VIES Declaration CZL");
        StatutoryReportingSetupCZL.Validate("VIES Declaration Report No.", Report::"VIES Declaration CZL");
        StatutoryReportingSetupCZL."VIES Decl. Auth. Employee No." := 'OSO0010';
        StatutoryReportingSetupCZL."VIES Decl. Filled Employee No." := 'OSO0020';
        StatutoryReportingSetupCZL."VAT Stat. Auth. Employee No." := 'OSO0010';
        StatutoryReportingSetupCZL."VAT Stat. Filled Employee No." := 'OSO0020';
        StatutoryReportingSetupCZL."Company Type" := StatutoryReportingSetupCZL."Company Type"::Corporate;
        StatutoryReportingSetupCZL.City := CreatePostCode.FindCity(CreatePostCode.Convert('GB-CB1 2FB'));
        StatutoryReportingSetupCZL.Street := XTheRing;
        StatutoryReportingSetupCZL."House No." := X5;
        StatutoryReportingSetupCZL."Tax Office Number" := X461;
        StatutoryReportingSetupCZL."Tax Office Region Number" := X3003;
        StatutoryReportingSetupCZL."Primary Business Activity Code" := '620200';

        CreateNoSeries.InitBaseSeries(
          StatutoryReportingSetupCZL."Company Official Nos.", XCO, XCompanyOfficial, 'OSO0010', 'OSO9990', '', '', 10);
        CreateNoSeries.InitBaseSeries(
          StatutoryReportingSetupCZL."VAT Control Report Nos.", XVCR, XVATControlReport, XVCR001, '', '', '', 1);
        CreateNoSeries.InitBaseSeries2(
          StatutoryReportingSetupCZL."VIES Declaration Nos.", XVIES, XVIESDeclaration, XVIES16001, '', '', '', 1);
        StatutoryReportingSetupCZL.Modify();
    end;

    var
        StatutoryReportingSetupCZL: Record "Statutory Reporting Setup CZL";
        CreatePostCode: Codeunit "Create Post Code";
        CreateVATStatementTemplate: Codeunit "Create VAT Statement Template";
        CreateVATStatementName: Codeunit "Create VAT Statement Name";
        XCRONUSInternational: Label 'CRONUS International';
        XAs: Label 'a.s.';
        XTestEmail: Label 'test@test.cz';
        XABC123: Label 'ABC123';
        XCzechRepublic: Label 'Czech Republic';
        XTheRing: Label 'The Ring';
        X5: Label '5';
        CreateNoSeries: Codeunit "Create No. Series";
        XCO: Label 'CO', Comment = 'Company Official';
        XCompanyOfficial: Label 'Company Official';
        XVCR: Label 'VCR', Comment = 'VAT Control Report';
        XVATControlReport: Label 'VAT Control Report';
        XVCR001: Label 'VCR001';
        XVIES: Label 'VIES';
        XVIESDeclaration: Label 'VIES Declaration';
        XVIES16001: Label 'VIES16001';
        X461: Label '461';
        X3003: Label '3003';

    procedure CreateEvaluationData()
    begin
        StatutoryReportingSetupCZL.Get();
        StatutoryReportingSetupCZL."Company Type" := StatutoryReportingSetupCZL."Company Type"::Corporate;
        StatutoryReportingSetupCZL."Company Trade Name" := XCRONUSInternational;
        StatutoryReportingSetupCZL."Company Trade Name Appendix" := XAs;
        StatutoryReportingSetupCZL."VAT Control Report E-mail" := XTestEmail;
        StatutoryReportingSetupCZL."Data Box ID" := XABC123;
        StatutoryReportingSetupCZL."Tax Payer Status" := StatutoryReportingSetupCZL."Tax Payer Status"::Payer;
        StatutoryReportingSetupCZL."VIES Decl. Auth. Employee No." := 'OSO0010';
        StatutoryReportingSetupCZL."VIES Decl. Filled Employee No." := 'OSO0020';
        StatutoryReportingSetupCZL."VAT Stat. Auth. Employee No." := 'OSO0010';
        StatutoryReportingSetupCZL."VAT Stat. Filled Employee No." := 'OSO0020';
        StatutoryReportingSetupCZL."Company Type" := StatutoryReportingSetupCZL."Company Type"::Corporate;
        StatutoryReportingSetupCZL.City := CreatePostCode.FindCity(CreatePostCode.Convert('GB-CB1 2FB'));
        StatutoryReportingSetupCZL.Street := XTheRing;
        StatutoryReportingSetupCZL."House No." := X5;
        StatutoryReportingSetupCZL."Tax Office Number" := X461;
        StatutoryReportingSetupCZL."Tax Office Region Number" := X3003;
        StatutoryReportingSetupCZL."Primary Business Activity Code" := '620200';
        StatutoryReportingSetupCZL.Modify();
    end;

    procedure InsertMiniAppData()
    begin
        StatutoryReportingSetupCZL.Get();
        StatutoryReportingSetupCZL."VAT Statement Template Name" := CreateVATStatementTemplate.GetVATName();
        StatutoryReportingSetupCZL."VAT Statement Name" := CreateVATStatementName.GetVAT('XVAT19');
        StatutoryReportingSetupCZL."Simplified Tax Document Limit" := 10000;
        StatutoryReportingSetupCZL."VAT Statement Country Name" := XCzechRepublic;
        StatutoryReportingSetupCZL."VIES Number of Lines" := 20;
        StatutoryReportingSetupCZL.Validate("VIES Declaration Export No.", Xmlport::"VIES Declaration CZL");
        StatutoryReportingSetupCZL.Validate("VIES Declaration Report No.", Report::"VIES Declaration CZL");
        StatutoryReportingSetupCZL.Validate("VAT Control Report Xml Format", StatutoryReportingSetupCZL."VAT Control Report Xml Format"::"03_01_03");

        CreateNoSeries.InitBaseSeries(
          StatutoryReportingSetupCZL."Company Official Nos.", XCO, XCompanyOfficial, 'OSO0010', 'OSO9990', '', '', 10);
        CreateNoSeries.InitBaseSeries(
          StatutoryReportingSetupCZL."VAT Control Report Nos.", XVCR, XVATControlReport, XVCR001, '', '', '', 1);
        CreateNoSeries.InitBaseSeries2(
          StatutoryReportingSetupCZL."VIES Declaration Nos.", XVIES, XVIESDeclaration, XVIES16001, '', '', '', 1);
        StatutoryReportingSetupCZL.Modify();
    end;
}