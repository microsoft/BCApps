codeunit 131304 "Library - Account Schedule"
{
    // Utility functions related to Account Schedule


    trigger OnRun()
    begin
    end;

    var
        AccSchedManagement: Codeunit AccSchedManagement;
        RoundingFormatTok: Label '<Precision,%1><Standard Format,0>', Locked = true;

    procedure CalcCell(var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean; IncludeSimEntries: Boolean): Decimal
    begin
        // Wrapper function
        IncludeSimEntries := false; // just for precal
        exit(AccSchedManagement.CalcCell(AccSchedLine, ColumnLayout, CalcAddCurr));
    end;

    procedure GetAutoFormatString(): Text
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GetCustomFormatString(GLSetup."Amount Decimal Places"));
    end;

    procedure GetCustomFormatString(Decimals: Text): Text
    begin
        exit(StrSubstNo(RoundingFormatTok, Decimals));
    end;
}

