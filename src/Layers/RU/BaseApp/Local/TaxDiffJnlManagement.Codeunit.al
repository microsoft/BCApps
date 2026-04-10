#pragma warning disable AA0247
codeunit 17300 TaxDiffJnlManagement
{
    Permissions = TableData "Tax Diff. Journal Template" = imd,
                  TableData "Tax Diff. Journal Batch" = imd;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Do you want to post the journals?';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label 'The journals were successfully posted.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'It was not possible to post all of the journals. ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'The journals that were not successfully posted are now marked.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'Do you want to post the journal lines?';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label 'The journal lines were successfully posted.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1000: Label '%1 journal';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1001: Label 'DEFAULT';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1002: Label 'Default Journal';
#pragma warning restore AA0074
        LastTaxDiffJnlLine: Record "Tax Diff. Journal Line";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        OpenFromBatch: Boolean;

    [Scope('OnPrem')]
    procedure TemplateSelection(PageID: Integer; PageTemplate: Option General; var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; var JnlSelected: Boolean)
    var
        TaxDiffJnlTemplate: Record "Tax Diff. Journal Template";
    begin
        JnlSelected := true;

        TaxDiffJnlTemplate.Reset();
        if not OpenFromBatch then
            TaxDiffJnlTemplate.SetRange("Page ID", PageID);
        TaxDiffJnlTemplate.SetRange(Type, PageTemplate);

        case TaxDiffJnlTemplate.Count of
            0:
                begin
                    TaxDiffJnlTemplate.Init();
                    TaxDiffJnlTemplate.Type := PageTemplate;
                    TaxDiffJnlTemplate.Name := Format(TaxDiffJnlTemplate.Type, MaxStrLen(TaxDiffJnlTemplate.Name));
                    TaxDiffJnlTemplate.Description := StrSubstNo(Text1000, TaxDiffJnlTemplate.Type);
                    TaxDiffJnlTemplate.Validate(Type);
                    TaxDiffJnlTemplate.Insert();
                    Commit();
                end;
            1:
                TaxDiffJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, TaxDiffJnlTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            TaxDiffJnlLine.FilterGroup := 2;
            TaxDiffJnlLine.SetRange("Journal Template Name", TaxDiffJnlTemplate.Name);
            TaxDiffJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                TaxDiffJnlLine."Journal Template Name" := '';
                PAGE.Run(TaxDiffJnlTemplate."Page ID", TaxDiffJnlLine);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure TemplateSelectionFromBatch(var TaxDiffJnlBatch: Record "Tax Diff. Journal Batch")
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        JnlSelected: Boolean;
    begin
        OpenFromBatch := true;
        TaxDiffJnlLine."Journal Batch Name" := TaxDiffJnlBatch.Name;
        TemplateSelection(0, 0, TaxDiffJnlLine, JnlSelected);
    end;

    [Scope('OnPrem')]
    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var TaxDiffJnlLine: Record "Tax Diff. Journal Line")
    begin
        CheckTemplateName(TaxDiffJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        TaxDiffJnlLine.FilterGroup := 2;
        TaxDiffJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        TaxDiffJnlLine.FilterGroup := 0;
    end;

    local procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
    begin
        TaxDiffJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        if not TaxDiffJnlBatch.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not TaxDiffJnlBatch.FindFirst() then begin
                TaxDiffJnlBatch.Init();
                TaxDiffJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
                TaxDiffJnlBatch.SetupNewBatch();
                TaxDiffJnlBatch.Name := Text1001;
                TaxDiffJnlBatch.Description := Text1002;
                TaxDiffJnlBatch.Insert(true);
                Commit();
            end;
            CurrentJnlBatchName := TaxDiffJnlBatch.Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckName(CurrentJnlBatchName: Code[10]; var TaxDiffJnlLine: Record "Tax Diff. Journal Line")
    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
    begin
        TaxDiffJnlBatch.Get(TaxDiffJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    [Scope('OnPrem')]
    procedure SetName(CurrentJnlBatchName: Code[10]; var TaxDiffJnlLine: Record "Tax Diff. Journal Line")
    begin
        TaxDiffJnlLine.FilterGroup := 2;
        TaxDiffJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        TaxDiffJnlLine.FilterGroup := 0;
        if TaxDiffJnlLine.Find('-') then;
    end;

    [Scope('OnPrem')]
    procedure LookupName(var CurrentJnlBatchName: Code[10]; var TaxDiffJnlLine: Record "Tax Diff. Journal Line")
    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
    begin
        Commit();
        TaxDiffJnlBatch."Journal Template Name" := TaxDiffJnlLine.GetRangeMax("Journal Template Name");
        TaxDiffJnlBatch.Name := TaxDiffJnlLine.GetRangeMax("Journal Batch Name");
        TaxDiffJnlBatch.FilterGroup := 2;
        TaxDiffJnlBatch.SetRange("Journal Template Name", TaxDiffJnlBatch."Journal Template Name");
        TaxDiffJnlBatch.FilterGroup := 0;
        if PAGE.RunModal(0, TaxDiffJnlBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := TaxDiffJnlBatch.Name;
            SetName(CurrentJnlBatchName, TaxDiffJnlLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetAccounts(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; var TaxDiffName: Text[50]; var SourceName: Text[100])
    var
        TaxDiff: Record "Tax Difference";
        FE: Record "Fixed Asset";
    begin
        if TaxDiffJnlLine."Tax Diff. Code" <> LastTaxDiffJnlLine."Tax Diff. Code" then begin
            TaxDiffName := '';
            if TaxDiffJnlLine."Tax Diff. Code" <> '' then
                if TaxDiff.Get(TaxDiffJnlLine."Tax Diff. Code") then
                    TaxDiffName := CopyStr(TaxDiff.Description, 1, MaxStrLen(TaxDiffName));
        end;

        if (TaxDiffJnlLine."Source Type" <> LastTaxDiffJnlLine."Source Type") or
           (TaxDiffJnlLine."Source No." <> LastTaxDiffJnlLine."Source No.")
        then begin
            SourceName := '';
            if TaxDiffJnlLine."Source No." <> '' then
                case TaxDiffJnlLine."Source Type" of
                    TaxDiffJnlLine."Source Type"::"Future Expense":
                        if FE.Get(TaxDiffJnlLine."Source No.") then
                            SourceName := FE.Description;
                end;
        end;

        LastTaxDiffJnlLine := TaxDiffJnlLine;
    end;

    [Scope('OnPrem')]
    procedure JnlBatchPost(var Rec: Record "Tax Diff. Journal Batch")
    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostJnlBatch: Codeunit "Tax Diff.-Post Jnl. Batch";
        JnlWithErrors: Boolean;
    begin
        TaxDiffJnlBatch.Copy(Rec);
        if not Confirm(Text000, false) then
            exit;

        TaxDiffJnlBatch.Find('-');
        repeat
            TaxDiffJnlLine.SetRange("Journal Template Name", TaxDiffJnlBatch."Journal Template Name");
            TaxDiffJnlLine.SetRange("Journal Batch Name", TaxDiffJnlBatch.Name);
            Clear(TaxDiffPostJnlBatch);
            if TaxDiffPostJnlBatch.Run(TaxDiffJnlLine) then
                TaxDiffJnlBatch.Mark(false)
            else begin
                TaxDiffJnlBatch.Mark(true);
                JnlWithErrors := true;
            end;
        until TaxDiffJnlBatch.Next() = 0;

        if not JnlWithErrors then
            Message(Text001)
        else
            Message(
              Text002 +
              Text003);

        if not TaxDiffJnlBatch.Find('=><') then begin
            TaxDiffJnlBatch.Reset();
            TaxDiffJnlBatch.FilterGroup(2);
            TaxDiffJnlBatch.SetRange("Journal Template Name", TaxDiffJnlBatch."Journal Template Name");
            TaxDiffJnlBatch.FilterGroup(0);
            TaxDiffJnlBatch.Name := '';
        end;

        Rec.Copy(TaxDiffJnlBatch);
        Commit();
    end;

    [Scope('OnPrem')]
    procedure JnlPost(var Rec: Record "Tax Diff. Journal Line")
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostJnlBatch: Codeunit "Tax Diff.-Post Jnl. Batch";
    begin
        TaxDiffJnlLine.Copy(Rec);
        if not Confirm(Text004, false) then
            exit;

        TaxDiffPostJnlBatch.Run(TaxDiffJnlLine);

        if TaxDiffJnlLine."Line No." = 0 then
            Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
        else
            Message(Text006);

        if not TaxDiffJnlLine.Find('=><') then begin
            TaxDiffJnlLine.Reset();
            TaxDiffJnlLine.FilterGroup(2);
            TaxDiffJnlLine.SetRange("Journal Template Name", TaxDiffJnlLine."Journal Template Name");
            TaxDiffJnlLine.SetRange("Journal Batch Name", TaxDiffJnlLine."Journal Batch Name");
            TaxDiffJnlLine.FilterGroup(0);
            TaxDiffJnlLine."Line No." := 10000;
        end;
        Rec.Copy(TaxDiffJnlLine);
        Commit();
    end;

    [Scope('OnPrem')]
    procedure JnlShowEntries(TaxDiffJnlLine: Record "Tax Diff. Journal Line")
    var
        TaxDiffEntry: Record "Tax Diff. Ledger Entry";
    begin
        case TaxDiffJnlLine."Source Type" of
            TaxDiffJnlLine."Source Type"::"Future Expense":
                begin
                    TaxDiffEntry.Reset();
                    TaxDiffEntry.SetRange("Tax Diff. Code", TaxDiffJnlLine."Tax Diff. Code");
                    TaxDiffEntry.SetRange("Source Type", TaxDiffJnlLine."Source Type");
                    TaxDiffEntry.SetRange("Source No.", TaxDiffJnlLine."Source No.");
                    PAGE.Run(0, TaxDiffEntry);
                end;
            else begin
                TaxDiffEntry.Reset();
                TaxDiffEntry.SetRange("Tax Diff. Code", TaxDiffJnlLine."Tax Diff. Code");
                PAGE.Run(0, TaxDiffEntry);
            end;
        end;
    end;
}

