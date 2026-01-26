codeunit 132442 "Test VAT Content"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    var
        VATReportArchive: Record "VAT Report Archive";
        LibraryUtility: Codeunit "Library - Utility";
        TempBlob: Codeunit "Temp Blob";
        ContentOutStream: OutStream;
#if not CLEAN27
        DummyGuid: Guid;
#endif
    begin
        TempBlob.CreateOutStream(ContentOutStream);
        ContentOutStream.WriteText(LibraryUtility.GenerateGUID());
#if not CLEAN27
        VATReportArchive.ArchiveSubmissionMessage("VAT Report Config. Code".AsInteger(), Rec."No.", TempBlob, DummyGuid);
#else
        VATReportArchive.ArchiveSubmissionMessage("VAT Report Config. Code".AsInteger(), Rec."No.", TempBlob);
#endif
    end;
}