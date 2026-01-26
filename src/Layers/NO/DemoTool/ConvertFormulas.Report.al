report 160804 "Convert Formulas"
{
    Caption = 'Convert Formulas';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Acc. Schedules Conversion"; "Acc. Schedules Conversion")
        {
            DataItemTableView = sorting("Schedule Name", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if Kontoskjema.Get("Schedule Name", "Line No.") then begin
                    Kontoskjema.Totaling := "Totaling (New)";
                    Kontoskjema.Modify();
                end;
            end;
        }
        dataitem("Analysis Conversion"; "Analysis Conversion")
        {
            DataItemTableView = sorting("Analysis Code");

            trigger OnAfterGetRecord()
            begin
                Analysevisning.Get("Analysis Code");
                Analysevisning."Account Filter" := "GL Acc Filter (New)";
                Analysevisning.Modify();
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        // MESSAGE('Formulas converted');
    end;

    var
        Kontoskjema: Record "Acc. Schedule Line";
        Analysevisning: Record "Analysis View";
}

