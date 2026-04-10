codeunit 132442 "Test VAT Content"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    var
        VATReportArchive: Record "VAT Report Archive";
        LibraryUtility: Codeunit "Library - Utility";
        TempBlob: Codeunit "Temp Blob";
        ContentOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(ContentOutStream);
        ContentOutStream.WriteText(LibraryUtility.GenerateGUID());
        VATReportArchive.ArchiveSubmissionMessage("VAT Report Config. Code".AsInteger(), Rec."No.", TempBlob);
    end;
}