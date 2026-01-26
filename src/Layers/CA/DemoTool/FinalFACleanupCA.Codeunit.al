codeunit 168110 "Final FA Cleanup - CA"
{

    trigger OnRun()
    begin
        FixedAsset.Reset();
        FixedAsset.Find('-');
        REPORT.RunModal(168110, false, false, FixedAsset);
        //Now post those puppies.
        FAJrnlLine.SetRange("Journal Template Name", 'ASSETS');
        FAJrnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        FAJrnlLine.Find('-');
        FAPostBatch.Run(FAJrnlLine);
        //now run report 5692
        FixedAsset.Reset();
        FixedAsset.Find('-');
        REPORT.RunModal(168110, false, false, FixedAsset);
        //and post again
        FAJrnlLine.Reset();
        FAJrnlLine.SetRange("Journal Template Name", 'ASSETS');
        FAJrnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        FAJrnlLine.Find('-');
        Clear(FAPostBatch);
        FAPostBatch.Run(FAJrnlLine);
    end;

    var
        FAJrnlLine: Record "FA Journal Line";
        FixedAsset: Record "Fixed Asset";
        FAPostBatch: Codeunit "FA Jnl.-Post Batch";
}

