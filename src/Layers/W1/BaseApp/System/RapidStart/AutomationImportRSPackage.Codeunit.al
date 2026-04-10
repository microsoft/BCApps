namespace System.IO;

using System.Utilities;

codeunit 5432 "Automation - Import RSPackage"
{
    TableNo = "Config. Package";

    trigger OnRun()
    var
        TenantConfigPackageFile: Record "Tenant Config. Package File";
        TempBlobDecompressed: Codeunit "Temp Blob";
        TempBlob: Codeunit "Temp Blob";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        InStream: InStream;
    begin
        Rec.Validate("Import Status", Rec."Import Status"::InProgress);
        Clear(Rec."Import Error");
        Rec.Modify(true);

        TenantConfigPackageFile.Get(Rec.Code);
        TempBlob.FromRecord(TenantConfigPackageFile, TenantConfigPackageFile.FieldNo(Content));

        ConfigXMLExchange.SetHideDialog(true);
        ConfigXMLExchange.DecompressPackageToBlob(TempBlob, TempBlobDecompressed);
        TempBlobDecompressed.CreateInStream(InStream);
        ConfigXMLExchange.ImportPackageXMLWithCodeFromStream(InStream, Rec.Code);

        // refreshing the record as ImportPackageXMLWithCodeFromStream updated the Configuration package with the number of records in the package, etc.
        Rec.Find();
        Rec.Validate("Import Status", Rec."Import Status"::Completed);
        Rec.Modify(true);
        Commit();
    end;
}

