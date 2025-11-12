report 103404 "Test Log"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution
    DefaultLayout = RDLC;
    RDLCLayout = './Test Log.rdlc';

    Permissions = TableData "Item Ledger Entry" = rimd;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            PrintOnlyIfDetail = true;
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(CETAF_Test_LogCaption; Text001)
            {
            }
            dataitem("Use Case"; "Use Case")
            {
                DataItemTableView = sorting("Use Case No.");
                column(FORMAT_UseCaseTested_; Format(UseCaseTested))
                {
                }
                column(Use_Case__Use_Case_No__; "Use Case No.")
                {
                }
                column(FORMAT_UseCaseOK_; Format(UseCaseOK))
                {
                }
                column(Use_Case_Description; Description)
                {
                }
                column(Test_Case__Test_Case_No__Caption; "Test Case".FieldCaption("Test Case No."))
                {
                }
                column(Use_Case__Use_Case_No__Caption; FieldCaption("Use Case No."))
                {
                }
                column(FORMAT_TestCaseTested_Caption; Text003)
                {
                }
                column(FORMAT_UseCaseTested_Caption; Text004)
                {
                }
                column(FORMAT_UseCaseOK_Caption; Text005)
                {
                }
                column(FORMAT_TestCaseOK_Caption; Text006)
                {
                }
                dataitem("Test Case"; "Test Case")
                {
                    DataItemLink = "Use Case No." = field("Use Case No.");
                    DataItemTableView = sorting("Use Case No.", "Test Case No.");
                    column(FORMAT_TestCaseTested_; Format(TestCaseTested))
                    {
                    }
                    column(Test_Case__Test_Case_No__; "Test Case No.")
                    {
                    }
                    column(FORMAT_TestCaseOK_; Format(TestCaseOK))
                    {
                    }
                    column(Test_Case_Description; Description)
                    {
                    }
                    column(Test_Case_Use_Case_No_; "Use Case No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TestCaseTested := false;

                        TestscriptResult.Reset();
                        TestscriptResult.SetCurrentKey("Use Case No.", "Test Case No.", "Iteration No.");
                        TestscriptResult.SetRange("Use Case No.", "Use Case No.");
                        TestscriptResult.SetRange("Test Case No.", "Test Case No.");
                        if TestscriptResult.Find('-') then
                            TestCaseTested := TestCaseTested or (TestscriptResult."Iteration No." <> 0);

                        NoOfLines := TestscriptResult.Count();
                        TestscriptResult.SetRange("Is Equal", false);
                        TestCaseOK := (not TestscriptResult.Find('-')) and (NoOfLines <> 0);
                    end;
                }
                dataitem(UseCaseSeparator; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                }

                trigger OnAfterGetRecord()
                begin
                    UseCaseTested := false;

                    TestscriptResult.Reset();
                    TestscriptResult.SetCurrentKey("Use Case No.", "Test Case No.", "Iteration No.");
                    TestscriptResult.SetRange("Use Case No.", "Use Case No.");
                    if TestscriptResult.Find('-') then
                        repeat
                            UseCaseTested := UseCaseTested or (TestscriptResult."Iteration No." <> 0);
                            TestscriptResult.SetRange("Test Case No.", TestscriptResult."Test Case No.");
                            TestscriptResult.Find('+');
                            TestscriptResult.SetRange("Test Case No.");
                        until TestscriptResult.Next() = 0;

                    NoOfLines := TestscriptResult.Count();
                    TestscriptResult.SetRange("Is Equal", false);
                    UseCaseOK := (not TestscriptResult.Find('-')) and (NoOfLines <> 0);
                end;
            }
            dataitem(CodeCoverage; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(FORMAT_Object_Type_0___Text___; Format(AllObj."Object Type", 0, '<Text>'))
                {
                }
                column(FORMAT_Object_ID_; Format(AllObj."Object ID"))
                {
                }
                column(Object_Name; AllObj."Object Name")
                {
                }
                column(FORMAT_Ratio_; Format(Ratio))
                {
                }
                column(CodeCoverage_Number; Number)
                {
                }
                column(Code_CoverageCaption; Text007)
                {
                }
                column(FORMAT_Object_Type_0___Text___Caption; Text008)
                {
                }
                column(FORMAT_Object_ID_Caption; Text009)
                {
                }
                column(Object_NameCaption; Text010)
                {
                }
                column(FORMAT_Ratio_Caption; Text011)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CoverageLine.Reset();
                    CoverageLine.SetRange("Object Type", ObjType[Number]);
                    CoverageLine.SetRange("Object ID", ObjectID[Number]);
                    CoverageLine.SetRange("Line Type", CoverageLine."Line Type"::Code);
                    CoverageLine.SetFilter("Line No.", '<>0');
                    NoOfLines := CoverageLine.Count();
                    CoverageLine.SetRange("No. of Hits", 0);
                    NoOfLinesCovered := NoOfLines - CoverageLine.Count();
                    if NoOfLines = 0 then
                        Ratio := 0
                    else begin
                        Ratio := NoOfLinesCovered / NoOfLines;
                        case Round(Ratio, 0.01) of
                            0:
                                Ratio := Round(Ratio, 0.01, '>');
                            1:
                                Ratio := Round(Ratio, 0.01, '<');
                            else
                                Ratio := Round(Ratio, 0.01);
                        end;
                    end;

                    AllObj.Init();
                    AllObj."Object Type" := ObjType[Number];
                    AllObj."Object ID" := ObjectID[Number];
                    if AllObj.Find() then;
                end;

                trigger OnPreDataItem()
                begin
                    ActElementNo := 0;
                    MaxElementNo := 0;
                    // InsCodeCoverRef(CoverageLine."Object Type"::Report,795,1.00);
                    InsCodeCoverRef(CoverageLine."Object Type"::Report, 1002, 1.0);
                    InsCodeCoverRef(CoverageLine."Object Type"::Codeunit, 22, 1.0);
                    InsCodeCoverRef(CoverageLine."Object Type"::Codeunit, 80, 1.0);
                    InsCodeCoverRef(CoverageLine."Object Type"::Codeunit, 90, 1.0);
                    InsCodeCoverRef(CoverageLine."Object Type"::Codeunit, 5895, 1.0);
                    InsCodeCoverRef(CoverageLine."Object Type"::Codeunit, 5802, 1.0);
                    SortCodeCoverRef();

                    SetRange(Number, 1, MaxElementNo);
                end;
            }
            dataitem("_Testscript Result"; "_Testscript Result")
            {
                DataItemTableView = sorting("Use Case No.", "Test Case No.", "Iteration No.", TableID) where("Use Case No." = filter(0));
                column(Testing_method______TestingMethod; 'Testing method: ' + TestingMethod)
                {
                }
                column(FORMAT__Expected_Value__; Format("Expected Value"))
                {
                }
                column(FORMAT_Value_; Format(Value))
                {
                }
                column(Object_Name_Control36; AllObj."Object Name")
                {
                }
                column(FORMAT_Object_ID__Control37; Format(AllObj."Object ID"))
                {
                }
                column(Testscript_Result_No_; "No.")
                {
                }
                column(FORMAT__Expected_Value__Caption; Text012)
                {
                }
                column(FORMAT_Value_Caption; Text013)
                {
                }
                column(Object_Name_Control36Caption; Text014)
                {
                }
                column(FORMAT_Object_ID__Control37Caption; Text015)
                {
                }
                column(Test_statisticsCaption; Text016)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    AllObj.Init();
                    AllObj."Object Type" := AllObj."Object Type"::Table;
                    AllObj."Object ID" := TableID;
                    if AllObj.Find() then;

                    Evaluate(ActualRecordsTested, Value);
                    Evaluate(ActualFieldsTested, "Expected Value");
                    TotalRecordsTested := TotalRecordsTested + ActualRecordsTested;
                    TotalFieldsTested := TotalFieldsTested + ActualFieldsTested;
                end;

                trigger OnPreDataItem()
                begin
                    ShowNoOfRecs := Count <> 0;

                    QASetup.Get();
                    if QASetup."Use Hardcoded Reference" then
                        TestingMethod := 'Hardcoded'
                    else
                        TestingMethod := 'Using reference tables';
                end;
            }
            dataitem(TotalTested; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(TotalFieldsTested; TotalFieldsTested)
                {
                }
                column(TotalRecordsTested; TotalRecordsTested)
                {
                }
                column(TotalTested_Number; Number)
                {
                }
                column(TOTALCaption; Text017)
                {
                }

                trigger OnPreDataItem()
                begin
                    if not ShowNoOfRecs then
                        CurrReport.Break();
                end;
            }
            dataitem(TestDuration; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Test_duration______Duration; 'Test duration: ' + Duration)
                {
                }
                column(TestDuration_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    msPerSecond := 1000;
                    msPerMinute := 60 * msPerSecond;
                    msPerHour := 60 * msPerMinute;
                    msPerDay := 24 * msPerHour;

                    TestscriptResult.Reset();
                    TestscriptResult.SetFilter("Use Case No.", '<>%1', 0);
                    if TestscriptResult.Find('-') then begin
                        TestStartDate := TestscriptResult.Date;
                        TestStartTime := TestscriptResult.Time;
                    end;
                    if TestscriptResult.Find('+') then begin
                        TestEndDate := TestscriptResult.Date;
                        TestEndTime := TestscriptResult.Time;
                    end;

                    if not ((TestStartDate <> 0D) or (TestStartTime <> 0T) or
                            (TestEndDate <> 0D) or (TestEndTime <> 0T))
                    then
                        CurrReport.Skip();

                    DateDifference := TestEndDate - TestStartDate;
                    TimeDifference := TestEndTime - TestStartTime;
                    TimeDifference := TimeDifference + (msPerDay * DateDifference);

                    while TimeDifference >= msPerHour do begin
                        DurationHours := DurationHours + 1;
                        TimeDifference := TimeDifference - msPerHour;
                    end;
                    while TimeDifference >= msPerMinute do begin
                        DurationMinutes := DurationMinutes + 1;
                        TimeDifference := TimeDifference - msPerMinute;
                    end;
                    while TimeDifference >= msPerSecond do begin
                        DurationSeconds := DurationSeconds + 1;
                        TimeDifference := TimeDifference - msPerSecond;
                    end;

                    Duration := Format(DurationHours) + ':';
                    if DurationMinutes < 10 then
                        Duration := Duration + '0';
                    Duration := Duration + Format(DurationMinutes) + ':';
                    if DurationSeconds < 10 then
                        Duration := Duration + '0';
                    Duration := Duration + Format(DurationSeconds);
                end;
            }
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

    var
        TestscriptResult: Record "_Testscript Result";
        CoverageLine: Record "Code Coverage";
        AllObj: Record AllObj;
        QASetup: Record "QA Setup";
        UseCaseTested: Boolean;
        TestCaseTested: Boolean;
        UseCaseOK: Boolean;
        TestCaseOK: Boolean;
        NoOfLines: Integer;
        NoOfLinesCovered: Integer;
        Ratio: Decimal;
        ObjType: array[100] of Option;
        ObjectID: array[100] of Integer;
        ExpectedRatio: array[100] of Decimal;
        ActElementNo: Integer;
        MaxElementNo: Integer;
        SortObjectType: Option;
        SortObjectID: Integer;
        SortExpectedRatio: Decimal;
        I1: Integer;
        I2: Integer;
        TestingMethod: Text[30];
        ShowNoOfRecs: Boolean;
        ActualRecordsTested: Integer;
        ActualFieldsTested: Integer;
        TotalRecordsTested: Integer;
        TotalFieldsTested: Integer;
        msPerSecond: Integer;
        msPerMinute: Integer;
        msPerHour: Integer;
        msPerDay: Integer;
        TestStartDate: Date;
        TestStartTime: Time;
        TestEndDate: Date;
        TestEndTime: Time;
        DateDifference: Integer;
        TimeDifference: Integer;
        DurationHours: Integer;
        DurationMinutes: Integer;
        DurationSeconds: Integer;
        Duration: Text[30];
        Text001: Label 'CETAF Test Log';
        Text003: Label 'Test Case Tested';
        Text004: Label 'Use Case Tested';
        Text005: Label 'Use Case OK';
        Text006: Label 'Test Case OK';
        Text007: Label 'Code Coverage';
        Text008: Label 'Object Type';
        Text009: Label 'Object ID';
        Text010: Label 'Object Name';
        Text011: Label 'Ratio';
        Text012: Label 'No. of fields tested';
        Text013: Label 'No. of records tested';
        Text014: Label 'Table Name';
        Text015: Label 'Table ID';
        Text016: Label 'Test statistics';
        Text017: Label 'TOTAL';

    [Scope('OnPrem')]
    procedure InsCodeCoverRef(NewObjectType: Option; NewObjectID: Integer; NewExpectedRatio: Decimal)
    begin
        if ActElementNo < ArrayLen(ObjType) then begin
            ActElementNo := ActElementNo + 1;
            ObjType[ActElementNo] := NewObjectType;
            ObjectID[ActElementNo] := NewObjectID;
            ExpectedRatio[ActElementNo] := NewExpectedRatio;
            MaxElementNo := ActElementNo;
        end;
    end;

    [Scope('OnPrem')]
    procedure SortCodeCoverRef()
    begin
        for I1 := 1 to MaxElementNo do
            for I2 := I1 + 1 to MaxElementNo do
                if (ObjType[I2] < ObjType[I1]) or
                   ((ObjType[I2] = ObjType[I1]) and (ObjectID[I2] < ObjectID[I1]))
                then begin
                    SortObjectType := ObjType[I1];
                    SortObjectID := ObjectID[I1];
                    SortExpectedRatio := ExpectedRatio[I1];

                    ObjType[I1] := ObjType[I2];
                    ObjectID[I1] := ObjectID[I2];
                    ExpectedRatio[I1] := ExpectedRatio[I2];

                    ObjType[I2] := SortObjectType;
                    ObjectID[I2] := SortObjectID;
                    ExpectedRatio[I2] := SortExpectedRatio;
                end;
    end;
}

