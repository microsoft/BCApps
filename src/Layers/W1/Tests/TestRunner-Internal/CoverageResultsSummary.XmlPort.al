xmlport 130006 "Coverage Results Summary"
{
    Direction = Export;
    Format = Xml;
    FormatEvaluate = Xml;
    InlineSchema = false;
    UseDefaultNamespace = false;
    UseLax = false;
    UseRequestPage = false;

    schema
    {
        textelement(CoverageData)
        {
            textelement(OverallCoverage)
            {
                textelement(checkinid1)
                {
                    XmlName = 'CheckinID';
                }
                textelement(TotalLines)
                {
                }
                textelement(TotalNewLines)
                {
                }
                textelement(TotalCoverage)
                {
                }
                textelement(TotalNewCodeCoverage)
                {
                }
            }
            tableelement("Code Coverage"; "Code Coverage")
            {
                XmlName = 'ObjectCodeCoverage';
                SourceTableView = sorting("Object Type", "Object ID", "Line No.") order(ascending) where("Line Type" = const(Object));
                textelement(CheckinID)
                {
                }
                textelement(ObjType)
                {
                }
                textelement(ObjectID)
                {
                }
                textelement(ObjectName)
                {
                }
                textelement(NoOfCodeLines)
                {
                }
                textelement(NoOfCoveredCodeLines)
                {
                }
                textelement(NoOfNewCodeLines)
                {
                }
                textelement(NoOfCoveredNewCodeLines)
                {
                }
                textelement(Coverage)
                {
                }
                textelement(NewCodeCoverage)
                {
                }
                textelement(NoOfCheckins)
                {
                }
                textelement(CyclomaticComplexity)
                {
                }
                textelement("Area")
                {
                }

                trigger OnAfterGetRecord()
                var
                    CodeCoverage2: Record "Code Coverage";
                    TotalLinesInObject: Integer;
                    LinesCovered: Integer;
                    NewLinesInObject: Integer;
                    NewLinesCovered: Integer;
                begin
                    if "Code Coverage"."Object ID" in [50000 .. 99999] then // free/prototypes range
                        currXMLport.Skip();

                    if SkipTestAndDemoData then
                        if "Code Coverage"."Object ID" in [100000 .. 199999] then // Skip tests, UPTK, demotool
                            currXMLport.Skip();

                    ObjType := Format("Code Coverage"."Object Type");
                    ObjectID := Format("Code Coverage"."Object ID");
                    ObjectName := "Code Coverage".Line;

                    // Total coverage
                    CodeCoverage2.Reset();
                    CodeCoverage2.SetRange("Object Type", "Code Coverage"."Object Type");
                    CodeCoverage2.SetRange("Object ID", "Code Coverage"."Object ID");
                    CodeCoverage2.SetRange("Line Type", CodeCoverage2."Line Type"::Code);
                    TotalLinesInObject := CodeCoverage2.Count();
                    CodeCoverage2.SetFilter("No. of Hits", '>%1', 0);
                    LinesCovered := CodeCoverage2.Count();
                    NoOfCoveredCodeLines := Format(LinesCovered);
                    NoOfCodeLines := Format(TotalLinesInObject);
                    Coverage := '0';
                    if TotalLinesInObject > 0 then
                        Coverage := Format(LinesCovered / TotalLinesInObject * 100, 0, 9);

                    // New code coverage
                    ChangelistCode.Reset();
                    ChangelistCode.SetRange("Object Type", ChangelistCode.GetObjectType("Code Coverage"));
                    ChangelistCode.SetRange("Object No.", "Code Coverage"."Object ID");
                    ChangelistCode.SetRange("Line Type", ChangelistCode."Line Type"::Code);
                    ChangelistCode.SetRange(Change, '+');
                    NewLinesInObject := ChangelistCode.Count();
                    ChangelistCode.SetRange(Coverage, ChangelistCode.Coverage::Full);
                    NewLinesCovered := ChangelistCode.Count();
                    NoOfCoveredNewCodeLines := Format(NewLinesCovered);
                    NoOfNewCodeLines := Format(NewLinesInObject);
                    NewCodeCoverage := '0';
                    if NewLinesInObject > 0 then
                        NewCodeCoverage := Format(NewLinesCovered / NewLinesInObject * 100, 0, 9);

                    // Checkins and complexity
                    Clear(ChangelistCode);
                    ChangelistCode.SetRange("Object Type", ChangelistCode.GetObjectType("Code Coverage"));
                    ChangelistCode.SetRange("Object No.", "Code Coverage"."Object ID");
                    ChangelistCode.SetRange("Line Type", ChangelistCode."Line Type"::Object);
                    if ChangelistCode.FindFirst() then;
                    NoOfCheckins := Format(ChangelistCode."No. of Checkins");
                    CyclomaticComplexity := Format(ChangelistCode."Cyclomatic Complexity");
                end;
            }

            trigger OnBeforePassVariable()
            var
                CodeCoverage2: Record "Code Coverage";
                LinesOfCode: Integer;
                LinesCovered: Integer;
                NewLinesOfCode: Integer;
                NewLinesCovered: Integer;
            begin
                // Total coverage
                CodeCoverage2.Reset();
                CodeCoverage2.SetRange("Line Type", CodeCoverage2."Line Type"::Code);
                if SkipTestAndDemoData then
                    CodeCoverage2.SetFilter("Object ID", '..49999|200000..')
                else
                    CodeCoverage2.SetFilter("Object ID", '..49999|100000..');

                LinesOfCode := CodeCoverage2.Count();
                CodeCoverage2.SetFilter("No. of Hits", '>%1', 0);
                LinesCovered := CodeCoverage2.Count();
                TotalLines := Format(LinesOfCode);
                TotalCoverage := '0';
                if LinesOfCode > 0 then
                    TotalCoverage := Format(LinesCovered / LinesOfCode * 100, 0, 9);

                // New code coverage
                ChangelistCode.Reset();
                ChangelistCode.SetRange("Line Type", ChangelistCode."Line Type"::Code);
                ChangelistCode.SetRange(Change, '+');
                if SkipTestAndDemoData then
                    ChangelistCode.SetFilter("Object No.", '..49999|200000..')
                else
                    ChangelistCode.SetFilter("Object No.", '..49999|100000..');

                NewLinesOfCode := ChangelistCode.Count();
                ChangelistCode.SetRange(Coverage, ChangelistCode.Coverage::Full);
                NewLinesCovered := ChangelistCode.Count();
                TotalNewLines := Format(NewLinesOfCode);
                TotalNewCodeCoverage := '0';
                if NewLinesOfCode > 0 then
                    TotalNewCodeCoverage := Format(NewLinesCovered / NewLinesOfCode * 100, 0, 9);
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

    trigger OnInitXmlPort()
    begin
        ObjType := '';
        ObjectID := '0';
    end;

    trigger OnPreXmlPort()
    begin
        CODEUNIT.Run(CODEUNIT::"Calculate Changelist Coverage");
    end;

    var
        ChangelistCode: Record "Changelist Code";
        SkipTestAndDemoData: Boolean;

    [Scope('OnPrem')]
    procedure SetSkipTestAndDemo(NewSkipTestAndDemoData: Boolean)
    begin
        SkipTestAndDemoData := NewSkipTestAndDemoData;
    end;

    [Scope('OnPrem')]
    procedure SetCheckinID(NewCheckinID: Text)
    begin
        CheckinID := NewCheckinID;
        CheckinID1 := NewCheckinID;
    end;
}

