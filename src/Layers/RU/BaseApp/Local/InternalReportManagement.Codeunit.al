#pragma warning disable AA0247
codeunit 12403 "Internal Report Management"
{
    Permissions = TableData "Invoice Posting Buffer" = rimd;

    trigger OnRun()
    begin
    end;

    var

    [Scope('OnPrem')]
    procedure SetBeginEndDate(var BeginDate: Date; var EndDate: Date)
    var
        SaveDate: Date;
    begin
        if EndDate = 0D then
            EndDate := WorkDate();
        if BeginDate > EndDate then begin
            SaveDate := BeginDate;
            BeginDate := EndDate;
            EndDate := SaveDate;
        end;
        if BeginDate = 0D then
            BeginDate := DMY2Date(1, 1, Date2DMY(EndDate, 3));
    end;

    procedure CreateGLCorrespondenceMatrix(var GLCorrespondenceBuffer: Record "G/L Correspondence Buffer"; var GLAccount1: Record "G/L Account"; var NumbLines: Integer; var NumbColumns: Integer; StartDate: Date; EndDate: Date; SkipZeroAmount: Boolean): Boolean
    var
        GLCorrespondence: Record "G/L Correspondence";
    begin
        GLCorrespondenceBuffer.Reset();
        GLCorrespondenceBuffer.DeleteAll();
        NumbColumns := 0;
        GLCorrespondence.SetCurrentKey("Credit Account No.", "Debit Account No.");
        GLCorrespondence.SetRange("Credit Account No.", GLAccount1."No.");
        if not (StartDate = 0D) then
            if not (EndDate = 0D) then
                GLCorrespondence.SetRange("Date Filter", StartDate, EndDate)
            else
                GLCorrespondence.SetRange("Date Filter", StartDate)
        else
            if not (EndDate = 0D) then
                GLCorrespondence.SetRange("Date Filter", 0D, EndDate);
        if GLAccount1.GetFilter("Source Type Filter") <> '' then
            GLCorrespondence.SetFilter("Credit Source Type Filter", GLAccount1.GetFilter("Source Type Filter"));
        if GLAccount1.GetFilter("Source No. Filter") <> '' then
            GLCorrespondence.SetFilter("Credit Source No. Filter", GLAccount1.GetFilter("Source No. Filter"));
        GLCorrespondenceBuffer.Type := GLCorrespondenceBuffer.Type::Credit;
        GLCorrespondenceBuffer.Init();
        if GLCorrespondence.Find('-') then
            repeat
                if not (StartDate = 0D) or not (EndDate = 0D) then begin
                    GLCorrespondence.CalcFields(Amount);
                    GLCorrespondenceBuffer.Amount := GLCorrespondence.Amount;
                end;
                if not (SkipZeroAmount and
                        (not (StartDate = 0D) or not (EndDate = 0D)) and
                        (GLCorrespondenceBuffer.Amount = 0))
                then begin
                    GLCorrespondenceBuffer."G/L Account" := GLCorrespondence."Debit Account No.";
                    NumbColumns := NumbColumns + 1;
                    GLCorrespondenceBuffer.Insert();
                    Commit();
                end;
            until GLCorrespondence.Next() = 0;
        NumbLines := 0;
        GLCorrespondence.Reset();
        GLCorrespondence.SetCurrentKey("Debit Account No.", "Credit Account No.");
        GLCorrespondence.SetRange("Debit Account No.", GLAccount1."No.");
        if not (StartDate = 0D) then
            if not (EndDate = 0D) then
                GLCorrespondence.SetRange("Date Filter", StartDate, EndDate)
            else
                GLCorrespondence.SetRange("Date Filter", StartDate)
        else
            if not (EndDate = 0D) then
                GLCorrespondence.SetRange("Date Filter", 0D, EndDate);
        if GLAccount1.GetFilter("Source Type Filter") <> '' then
            GLCorrespondence.SetFilter("Debit Source Type Filter", GLAccount1.GetFilter("Source Type Filter"));
        if GLAccount1.GetFilter("Source No. Filter") <> '' then
            GLCorrespondence.SetFilter("Debit Source No. Filter", GLAccount1.GetFilter("Source No. Filter"));
        GLCorrespondenceBuffer.Init();
        GLCorrespondenceBuffer.Type := GLCorrespondenceBuffer.Type::Debit;
        if GLCorrespondence.Find('-') then
            repeat
                if not (StartDate = 0D) or not (EndDate = 0D) then begin
                    GLCorrespondence.CalcFields(Amount);
                    GLCorrespondenceBuffer.Amount := GLCorrespondence.Amount;
                end;
                if not (SkipZeroAmount and
                        (not (StartDate = 0D) or not (EndDate = 0D)) and
                        (GLCorrespondenceBuffer.Amount = 0))
                then begin
                    GLCorrespondenceBuffer."G/L Account" := GLCorrespondence."Credit Account No.";
                    NumbLines := NumbLines + 1;
                    GLCorrespondenceBuffer.Insert();
                end;
            until GLCorrespondence.Next() = 0;
        exit((NumbLines > 0) and (NumbColumns > 0));
    end;
}

