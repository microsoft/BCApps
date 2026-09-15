codeunit 163422 "Create Stat. Reporting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        "Statutory Report Setup".Get();
        "Create No. Series".InsertSeriesOnly("Statutory Report Setup"."Report Export Log Nos", XEREXPORT, XElectronicReportingExport, true, false, true);
        "Create No. Series".InsertSeriesLine("Statutory Report Setup"."Report Export Log Nos", XRE, 10000, 19030101D, 1);
        "Create No. Series".InsertSeriesOnly("Statutory Report Setup"."Report Data Nos", XERIMPORT, XElectronicReportingImport, true, false, true);
        "Create No. Series".InsertSeriesLine("Statutory Report Setup"."Report Data Nos", XRI, 10000, 19030101D, 1);
        "Statutory Report Setup"."Use XML Schema Validation" := true;
        "Statutory Report Setup"."Dflt. XML File Name Elem. Name" := XIdFile;
        "Statutory Report Setup"."Setup Mode" := true;
        "Statutory Report Setup"."Default Comp. Addr. Code" := XLEGAL;
        "Statutory Report Setup"."Default Comp. Addr. Lang. Code" := 'RUS';
        "Statutory Report Setup".Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        "Statutory Report Setup": Record "Statutory Report Setup";
        XLEGAL: Label 'LEGAL';
        "Create No. Series": Codeunit "Create No. Series";
        XEREXPORT: Label 'ER-EXPORT';
        XElectronicReportingExport: Label 'Electronic Reporting Export Log';
        XERIMPORT: Label 'ER-IMPORT';
        XElectronicReportingImport: Label 'Electronic Reporting Import Log';
        XRE: Label 'RE';
        XRI: Label 'RI';
        XIdFile: Label 'IdFile';
}

