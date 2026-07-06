codeunit 130027 "Calculate Changelist Coverage"
{

    trigger OnRun()
    var
        NoOfLinesInTrigger: Decimal;
        NoOfLinesInObject: Decimal;
        NoOfHitLinesInTrigger: Decimal;
        NoOfHitLinesInObject: Decimal;
    begin
        OpenWindow(UpdatingCoverageTxt, ChangelistCode.Count());

        ChangelistCode.SetFilter("Line Type", '%1|%2|%3',
        ChangelistCode."Line Type"::Object,
        ChangelistCode."Line Type"::"Trigger/Function",
        ChangelistCode."Line Type"::Code);
        ChangelistCode.ModifyAll(Coverage, ChangelistCode.Coverage::None);
        ChangelistCode.ModifyAll("Coverage %", 0.0);
        ChangelistCode.Reset();

        if ChangelistCode.FindSet() then
            repeat
                UpdateWindow();

                case ChangelistCode."Line Type" of
                    ChangelistCode."Line Type"::Object:
                        ProcessObjectCoverage(NoOfLinesInTrigger, NoOfLinesInObject, NoOfHitLinesInTrigger, NoOfHitLinesInObject);
                    ChangelistCode."Line Type"::"Trigger/Function":
                        ProcessTriggerCoverage(NoOfLinesInTrigger, NoOfHitLinesInTrigger);
                    ChangelistCode."Line Type"::Code:
                        ProcessCodeCoverage(NoOfLinesInTrigger, NoOfLinesInObject, NoOfHitLinesInTrigger, NoOfHitLinesInObject);
                end;
            until ChangelistCode.Next() = 0;

        Window.Close();
    end;

    var
        ChangelistCode: Record "Changelist Code";
        TriggerChangelistCode: Record "Changelist Code";
        ObjectChangelistCode: Record "Changelist Code";
        CodeCoverage: Record "Code Coverage";
        TriggerCodeCoverage: Record "Code Coverage";
        ObjectCodeCoverage: Record "Code Coverage";
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        NoOfRecords: Integer;
        i: Integer;
        UpdatingCoverageTxt: Label 'Updating coverage...  @1@@@@@@@';

    local procedure ProcessObjectCoverage(var NoOfLinesInTrigger: Decimal; var NoOfLinesInObject: Decimal; var NoOfHitLinesInTrigger: Decimal; var NoOfHitLinesInObject: Decimal)
    begin
        NoOfLinesInObject := 0;
        NoOfHitLinesInObject := 0;
        NoOfLinesInTrigger := 0;
        NoOfHitLinesInTrigger := 0;
        ObjectChangelistCode := ChangelistCode;
        ObjectChangelistCode.Coverage := ChangelistCode.Coverage::None;
        Clear(CodeCoverage);
        Clear(TriggerCodeCoverage);
        if not CodeCoverage.IsEmpty() then begin
            CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Object);
            CodeCoverage.SetRange("Object Type", GetObjectType(ChangelistCode));
            CodeCoverage.SetRange("Object ID", ChangelistCode."Object No.");
            ObjectCodeCoverage.Copy(CodeCoverage);
            if CodeCoverage.FindSet() then
                ObjectCodeCoverage := CodeCoverage
            else
                ObjectCodeCoverage.Init();
            CodeCoverage.Reset();
        end;
    end;

    local procedure ProcessTriggerCoverage(var NoOfLinesInTrigger: Decimal; var NoOfHitLinesInTrigger: Decimal)
    var
        Found: Boolean;
    begin
        if CodeCoverage."Object ID" <> 0 then begin
            NoOfLinesInTrigger := 0;
            NoOfHitLinesInTrigger := 0;

            TriggerChangelistCode := ChangelistCode;
            TriggerCodeCoverage.Copy(ObjectCodeCoverage);
            TriggerCodeCoverage.SetRange("Line Type", TriggerCodeCoverage."Line Type"::"Trigger/Function");
            if (not TriggerChangelistCode.Line.Contains('>')) and
               (not TriggerChangelistCode.Line.Contains('<')) and
               (not TriggerChangelistCode.Line.Contains('(')) and
               (not TriggerChangelistCode.Line.Contains(')'))
            then
                TriggerCodeCoverage.SetFilter(Line, TriggerChangelistCode.Line + '*');
            Found := false;
            if TriggerCodeCoverage.FindSet() then
                repeat
                    if TriggerCodeCoverage.Line[StrLen(TriggerCodeCoverage.Line) + 1] = '(' then
                        Found := true;
                until true in [Found, TriggerCodeCoverage.Next() = 0];

            if not Found then
                Clear(TriggerCodeCoverage);
            TriggerChangelistCode.Coverage := ChangelistCode.Coverage::None;
        end;
    end;

    local procedure ProcessCodeCoverage(var NoOfLinesInTrigger: Decimal; var NoOfLinesInObject: Decimal; var NoOfHitLinesInTrigger: Decimal; var NoOfHitLinesInObject: Decimal)
    var
        Position: Integer;
    begin
        if TriggerCodeCoverage."Object ID" <> 0 then begin
            Position :=
              TriggerCodeCoverage."Line No." +
              (ChangelistCode."Code Coverage Line No." - TriggerChangelistCode."Code Coverage Line No.");

            if not CodeCoverage.Get(TriggerCodeCoverage."Object Type", TriggerCodeCoverage."Object ID", Position) then
                exit;

            if CodeCoverage.Line.TrimStart().ToUpper() = ChangelistCode.Line.TrimStart().ToUpper() then
                if CodeCoverage."Line Type" = CodeCoverage."Line Type"::Empty then begin
                    ChangelistCode."Line Type" := ChangelistCode."Line Type"::Empty;
                    ChangelistCode.Modify();
                end else begin
                    NoOfLinesInTrigger += 1;
                    NoOfLinesInObject += 1;
                    if CodeCoverage."No. of Hits" > 0 then begin
                        NoOfHitLinesInTrigger += 1;
                        NoOfHitLinesInObject += 1;
                        UpdateCoverage(ChangelistCode, 1, 1, CodeCoverage."Line No.");
                    end else
                        UpdateCoverage(ChangelistCode, 0, 1, CodeCoverage."Line No.");
                    UpdateCoverage(TriggerChangelistCode, NoOfHitLinesInTrigger, NoOfLinesInTrigger, TriggerCodeCoverage."Line No.");
                    UpdateCoverage(ObjectChangelistCode, NoOfHitLinesInObject, NoOfLinesInObject, ObjectCodeCoverage."Line No.");
                end;
        end;
    end;

    local procedure GetCoverage(NoOfHitLines: Decimal; NoOfLines: Decimal): Integer
    begin
        if NoOfHitLines = 0 then
            exit(ChangelistCode.Coverage::None);
        if NoOfHitLines <> NoOfLines then
            exit(ChangelistCode.Coverage::Partial);
        exit(ChangelistCode.Coverage::Full);
    end;

    local procedure GetObjectType(ChangelistCode: Record "Changelist Code"): Integer
    begin
        case ChangelistCode."Object Type" of
            ChangelistCode."Object Type"::Table:
                exit(CodeCoverage."Object Type"::Table);
            ChangelistCode."Object Type"::Codeunit:
                exit(CodeCoverage."Object Type"::Codeunit);
            ChangelistCode."Object Type"::Report:
                exit(CodeCoverage."Object Type"::Report);
            ChangelistCode."Object Type"::Page:
                exit(CodeCoverage."Object Type"::Page);
            ChangelistCode."Object Type"::XMLPort:
                exit(CodeCoverage."Object Type"::XMLport);
        end;
    end;

    local procedure UpdateCoverage(ChangelistCode: Record "Changelist Code"; NoOfHitLines: Decimal; NoOfLines: Decimal; Position: Integer)
    begin
        ChangelistCode."Coverage %" := Round(NoOfHitLines / NoOfLines * 100, 0.01);
        ChangelistCode.Coverage := GetCoverage(NoOfHitLines, NoOfLines);
        ChangelistCode."Code Coverage Line No." := Position;
        ChangelistCode.Modify();
    end;

    local procedure OpenWindow(DisplayText: Text[250]; NoOfRecords2: Integer)
    begin
        i := 0;
        NoOfRecords := NoOfRecords2;
        WindowUpdateDateTime := CurrentDateTime;
        Window.Open(DisplayText);
    end;

    local procedure UpdateWindow()
    begin
        i := i + 1;
        if CurrentDateTime - WindowUpdateDateTime >= 300 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, Round(i / NoOfRecords * 10000, 1));
        end;
    end;
}

