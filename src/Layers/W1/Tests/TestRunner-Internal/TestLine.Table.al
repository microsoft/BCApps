table 130021 "Test Line"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Test Suite"; Code[10])
        {
            TableRelation = "Test Suite".Name;
        }
        field(2; "Line No."; Integer)
        {
            AutoIncrement = true;
        }
        field(3; "Line Type"; Option)
        {
            Editable = false;
            InitValue = "Codeunit";
            OptionMembers = Group,"Codeunit","Function",SCENARIO,GIVEN,WHEN,"THEN";

            trigger OnValidate()
            begin
                case "Line Type" of
                    "Line Type"::Group:
                        TestField("Test Codeunit", 0);
                    "Line Type"::Codeunit:
                        begin
                            TestField("Function", '');
                            Name := '';
                        end;
                end;

                UpdateLevelNo();
            end;
        }
        field(4; "Test Codeunit"; Integer)
        {
            Editable = false;
            TableRelation = if ("Line Type" = const(Codeunit)) AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit),
                                                                                                  "Object Subtype" = const('Test'));

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                if "Test Codeunit" = 0 then
                    exit;
                TestField("Function", '');
                if "Line Type" = "Line Type"::Group then
                    TestField("Test Codeunit", 0);
                if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, "Test Codeunit") then
                    Name := AllObjWithCaption."Object Name";
                UpdateLevelNo();
            end;
        }
        field(5; Name; Text[128])
        {
            Editable = false;

            trigger OnValidate()
            var
                TestUnitNo: Integer;
            begin
                case "Line Type" of
                    "Line Type"::Group:
                        ;
                    "Line Type"::"Function":
                        TestField(Name, "Function");
                    "Line Type"::Codeunit:
                        begin
                            TestField(Name);
                            Evaluate(TestUnitNo, Name);
                            Validate("Test Codeunit", TestUnitNo);
                        end;
                end;
            end;
        }
        field(6; "Function"; Text[128])
        {
            Editable = false;

            trigger OnValidate()
            begin
                if not ("Line Type" in ["Line Type"::"Function" .. "Line Type"::"THEN"]) then begin
                    TestField("Function", '');
                    exit;
                end;
                UpdateLevelNo();
                Name := "Function";
            end;
        }
        field(7; Run; Boolean)
        {

            trigger OnValidate()
            begin
                if "Function" = 'OnRun' then
                    Error(CannotChangeValueErr);
                TestLine.Copy(Rec);
                UpdateGroup(TestLine);
                UpdateChildren(TestLine);
            end;
        }
        field(8; Result; Option)
        {
            Editable = false;
            OptionMembers = " ",Failure,Success,Skipped;

            trigger OnValidate()
            begin
                "First Error" := '';
            end;
        }
        field(9; "First Error"; Text[2048])
        {
            Editable = false;
        }
        field(10; "Start Time"; DateTime)
        {
            Editable = false;
        }
        field(11; "Finish Time"; DateTime)
        {
            Editable = false;
        }
        field(12; Level; Integer)
        {
            Editable = false;
        }
        field(13; "Hit Objects"; Integer)
        {
            CalcFormula = count("CAL Test Coverage Map" where("Test Codeunit ID" = field("Test Codeunit")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "No. of Tests"; Integer)
        {
            BlankZero = true;
            CalcFormula = count("Test Line" where("Test Suite" = field("Test Suite"),
                                                   "Test Codeunit" = field("Test Codeunit"),
                                                   "Line Type" = const(Function)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Feature Tags"; Text[250])
        {
        }
    }

    keys
    {
        key(Key1; "Test Suite", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Test Suite", Result, "Line Type", Run)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteChildren();
    end;

    trigger OnInsert()
    begin
        if "Line Type" = "Line Type"::Codeunit then
            TestMgt.RunSuite(Rec, false);
    end;

    trigger OnModify()
    begin
        if ("Line Type" = "Line Type"::Codeunit) and
           ("Test Codeunit" <> xRec."Test Codeunit")
        then
            TestMgt.RunSuite(Rec, false);
    end;

    var
        TestLine: Record "Test Line";
        CannotChangeValueErr: Label 'You cannot change the value of the OnRun.', Locked = true;
        TestMgt: Codeunit "Test Management";

    [Scope('OnPrem')]
    procedure AddTestSteps() NoOfSteps: Integer
    var
        CodeunitTestLine: Record "Test Line";
        StepTestLine: Record "Test Line";
        TempCodeCoverage: Record "Code Coverage" temporary;
        FeatureTags: Text;
    begin
        if not TestMgt.IsCALCodeRead("Test Codeunit") then
            if not TestMgt.ReadCALCode("Test Codeunit", false) then
                exit(0);
        if not TestMgt.FindCALCodeLine("Test Codeunit", "Function", TempCodeCoverage) then
            exit(-1);
        if TempCodeCoverage.FindSet() then begin
            if GetFeatureTags(TempCodeCoverage, FeatureTags) then
                if "Function" = 'OnRun' then begin
                    "Feature Tags" := CopyStr(FeatureTags, 1, MaxStrLen("Feature Tags"));
                    CodeunitTestLine := Rec;
                    CodeunitTestLine.Find('<');
                    CodeunitTestLine."Feature Tags" := CopyStr(FeatureTags, 1, MaxStrLen("Feature Tags"));
                    CodeunitTestLine.Modify();
                end else
                    "Feature Tags" := CopyStr(FeatureTags + ' ' + "Feature Tags", 1, MaxStrLen("Feature Tags"));
            StepTestLine."Line No." := "Line No.";
            TempCodeCoverage.SetRange("Line Type", 5); // step tags
            if TempCodeCoverage.FindSet() then
                repeat
                    StepTestLine.Init();
                    StepTestLine.Name := CopyStr(TempCodeCoverage.Line, 1, MaxStrLen(StepTestLine.Name));
                    StepTestLine.ExtractStepTypeFromName();
                    StepTestLine."Test Suite" := "Test Suite";
                    StepTestLine."Line No." += 1;
                    StepTestLine."Test Codeunit" := "Test Codeunit";
                    StepTestLine."Function" := "Function";
                    StepTestLine."Feature Tags" := "Feature Tags";
                    StepTestLine.Level := 3;
                    StepTestLine.Insert();
                    NoOfSteps += 1;
                until TempCodeCoverage.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ExtractStepTypeFromName()
    var
        UpperCaseName: Text;
    begin
        "Line Type" := "Line Type"::SCENARIO;
        UpperCaseName := UpperCase(Name);
        if StrPos(UpperCaseName, '[SCENARIO') <> 0 then
            "Line Type" := "Line Type"::SCENARIO;
        if StrPos(UpperCaseName, '[GIVEN]') <> 0 then
            "Line Type" := "Line Type"::GIVEN;
        if StrPos(UpperCaseName, '[WHEN]') <> 0 then
            "Line Type" := "Line Type"::WHEN;
        if StrPos(UpperCaseName, '[THEN]') <> 0 then
            "Line Type" := "Line Type"::"THEN";
        Name := ' ' + CopyStr(Name, StrPos(Name, ']') + 1);
    end;

    [Scope('OnPrem')]
    procedure GetFeatureTags(var TempCodeCoverage: Record "Code Coverage" temporary; var FeatureTags: Text): Boolean
    var
        Pos: Integer;
    begin
        FeatureTags := '';
        TempCodeCoverage.SetRange("Line Type", 4); // feature tags
        if TempCodeCoverage.FindFirst() then begin
            Pos := StrPos(UpperCase(TempCodeCoverage.Line), '[FEATURE]');
            FeatureTags := CopyStr(TempCodeCoverage.Line, Pos + 10);
        end;
        exit(FeatureTags <> '');
    end;

    [Scope('OnPrem')]
    procedure UpdateGroup(var TestLine: Record "Test Line")
    var
        CopyOfTestLine: Record "Test Line";
        OutOfGroup: Boolean;
    begin
        if not TestLine.Run then
            exit;
        if "Line Type" <> "Line Type"::"Function" then
            exit;

        CopyOfTestLine.Copy(TestLine);
        TestLine.Reset();
        TestLine.SetRange("Test Suite", TestLine."Test Suite");
        repeat
            OutOfGroup :=
              (TestLine.Next(-1) = 0) or
              (TestLine."Test Codeunit" <> CopyOfTestLine."Test Codeunit");

            if ((TestLine."Line Type" in [TestLine."Line Type"::Group, TestLine."Line Type"::Codeunit]) or (TestLine."Function" = 'OnRun')) and
               not TestLine.Run
            then begin
                TestLine.Run := true;
                TestLine.Modify();
            end;
        until OutOfGroup;
        TestLine.Copy(CopyOfTestLine);
    end;

    [Scope('OnPrem')]
    procedure UpdateChildren(var TestLine: Record "Test Line")
    var
        CopyOfTestLine: Record "Test Line";
    begin
        if TestLine."Line Type" in ["Line Type"::"Function" .. "Line Type"::"THEN"] then
            exit;

        CopyOfTestLine.Copy(TestLine);
        TestLine.Reset();
        TestLine.SetRange("Test Suite", TestLine."Test Suite");
        TestLine.SetFilter("Line Type", '<%1', TestLine."Line Type"::SCENARIO);
        while (TestLine.Next() <> 0) and not (TestLine."Line Type" in [TestLine."Line Type"::Group, CopyOfTestLine."Line Type"]) do begin
            TestLine.Run := CopyOfTestLine.Run;
            TestLine.Modify();
        end;
        TestLine.Copy(CopyOfTestLine);
    end;

    [Scope('OnPrem')]
    procedure GetMinCodeunitLineNo() MinLineNo: Integer
    var
        TestLine: Record "Test Line";
    begin
        TestLine.Copy(Rec);
        TestLine.Reset();
        TestLine.SetRange("Test Suite", TestLine."Test Suite");

        MinLineNo := TestLine."Line No.";
        repeat
            MinLineNo := TestLine."Line No.";
        until (TestLine.Level < 2) or (TestLine.Next(-1) = 0);
    end;

    [Scope('OnPrem')]
    procedure GetMaxGroupLineNo() MaxLineNo: Integer
    var
        TestLine: Record "Test Line";
    begin
        TestLine.Copy(Rec);
        TestLine.Reset();
        TestLine.SetRange("Test Suite", TestLine."Test Suite");

        MaxLineNo := TestLine."Line No.";
        while (TestLine.Next() <> 0) and (TestLine.Level >= Rec.Level) do
            MaxLineNo := TestLine."Line No.";
    end;

    [Scope('OnPrem')]
    procedure GetMaxCodeunitLineNo(var NoOfFunctions: Integer) MaxLineNo: Integer
    var
        TestLine: Record "Test Line";
    begin
        TestField("Test Codeunit");
        NoOfFunctions := 0;

        TestLine.Copy(Rec);
        TestLine.Reset();
        TestLine.SetRange("Test Suite", TestLine."Test Suite");
        MaxLineNo := TestLine."Line No.";
        while (TestLine.Next() <> 0) and (TestLine."Line Type" in [TestLine."Line Type"::"Function" .. TestLine."Line Type"::"THEN"]) do begin
            MaxLineNo := TestLine."Line No.";
            if TestLine.Run then
                NoOfFunctions += 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteChildren()
    var
        CopyOfTestLine: Record "Test Line";
        FromLineNo: Integer;
        ToLineNo: Integer;
    begin
        FromLineNo := "Line No." + 1;
        ToLineNo := FindLastChildLineNo();
        if (FromLineNo <= ToLineNo) or (ToLineNo = 0) then begin
            CopyOfTestLine.Copy(Rec);
            DeleteLinesInRange(FromLineNo, ToLineNo);
            Copy(CopyOfTestLine);
        end;
    end;

    local procedure DeleteLinesInRange(FromLineNo: Integer; ToLineNo: Integer)
    begin
        Reset();
        SetRange("Test Suite", "Test Suite");
        if ToLineNo = 0 then
            SetFilter("Line No.", '%1..', FromLineNo)
        else
            SetRange("Line No.", FromLineNo, ToLineNo);
        if not IsEmpty() then
            DeleteAll();
    end;

    local procedure FindLastChildLineNo(): Integer
    var
        NextTestLine: Record "Test Line";
    begin
        NextTestLine := Rec;
        NextTestLine.SetRange("Test Suite", "Test Suite");
        NextTestLine.SetRange(Level, 0, Level);
        if NextTestLine.Next() <> 0 then
            exit(NextTestLine."Line No." - 1);
    end;

    [Scope('OnPrem')]
    procedure CalcTestResults(var Success: Integer; var Fail: Integer; var Skipped: Integer; var NotExecuted: Integer)
    var
        TestLine: Record "Test Line";
    begin
        TestLine.SetRange("Test Suite", "Test Suite");
        TestLine.SetFilter("Function", '<>%1', 'OnRun');
        TestLine.SetRange("Line Type", "Line Type"::"Function");

        TestLine.SetRange(Result, Result::Success);
        Success := TestLine.Count();

        TestLine.SetRange(Result, Result::Failure);
        Fail := TestLine.Count();

        TestLine.SetRange(Result, Result::Skipped);
        Skipped := TestLine.Count();

        TestLine.SetRange(Result, Result::" ");
        NotExecuted := TestLine.Count();
    end;

    local procedure UpdateLevelNo()
    begin
        case "Line Type" of
            "Line Type"::Group:
                Level := 0;
            "Line Type"::Codeunit:
                Level := 1;
            "Line Type"::"Function":
                Level := 2;
            "Line Type"::SCENARIO .. "Line Type"::"THEN":
                Level := 3;
        end;
    end;
}

