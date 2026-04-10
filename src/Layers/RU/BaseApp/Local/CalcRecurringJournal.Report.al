#pragma warning disable AA0247
report 12429 "Calc. Recurring Journal"
{
    Caption = 'Calc. Recurring Journal';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if ("Acc. Schedule Name" <> '') and ("Column Layout Name" <> '') then begin
                    AccScheduleName.Get("Acc. Schedule Name");
                    if AccScheduleName."Analysis View Name" <> '' then
                        AnalysisView.Get(AccScheduleName."Analysis View Name");
                    AccScheduleLine.Get("Acc. Schedule Name", "Acc. Schedule Line No.");
                    AccScheduleLine.SetRange("Date Filter", StartingDate, EndingDate);
                    ColumnLayout.Get("Column Layout Name", "Column Layout Line No.");
                    Validate(Amount, AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false));
                    Modify();
                end
            end;

            trigger OnPreDataItem()
            begin
                CopyFilters(GenJournalLine);
                FilterGroup(2);
                if (GetFilter("Journal Template Name") = '') or (GetFilter("Journal Batch Name") = '') then
                    Error(Text000);
                FilterGroup(0);
            end;
        }
    }

    requestpage
    {
        DeleteAllowed = false;
        InsertAllowed = false;
        ModifyAllowed = false;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if StartingDate = 0D then
            Error(Text001);

        if EndingDate = 0D then
            Error(Text002);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Your must define Template Name and Batch Name for calculation.';
#pragma warning restore AA0074
        GenJournalLine: Record "Gen. Journal Line";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AnalysisView: Record "Analysis View";
        AccSchedManagement: Codeunit AccSchedManagement;
        StartingDate: Date;
        EndingDate: Date;
#pragma warning disable AA0074
        Text001: Label 'You must define Starting Date.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'You must define Ending Date.';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure SetParameters(var NewGenJournalLine: Record "Gen. Journal Line")
    var
        NewDateFormula: Text[30];
    begin
        GenJournalLine.CopyFilters(NewGenJournalLine);
        NewGenJournalLine.TestField("Recurring Frequency");
        EndingDate := NewGenJournalLine."Posting Date";
        NewDateFormula := '- (' + Format(NewGenJournalLine."Recurring Frequency") + ')';
        StartingDate := CalcDate(NewDateFormula, EndingDate) + 1;
    end;
}

