xmlport 130005 "Coverage Results Detailed"
{
    Direction = Export;
    Format = Xml;
    FormatEvaluate = Xml;
    InlineSchema = false;
    UseDefaultNamespace = false;
    UseLax = false;

    schema
    {
        textelement(CoverageData)
        {
            tableelement("Code Coverage"; "Code Coverage")
            {
                XmlName = 'CodeCoverage';
                SourceTableView = sorting("Object Type", "Object ID", "Line No.") order(ascending);
                textelement(CheckinID)
                {
                }
                textelement(ObjType)
                {
                }
                fieldelement(ObjectID; "Code Coverage"."Object ID")
                {
                }
                textelement(ObjectName)
                {
                }
                textelement(FunctionName)
                {
                }
                fieldelement(LineNo; "Code Coverage"."Line No.")
                {
                }
                textelement(LineType)
                {
                }
                fieldelement(Line; "Code Coverage".Line)
                {
                }
                textelement(NewOrChanged)
                {
                }
                textelement(IsEmptyLine)
                {
                }
                textelement(Covered)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Code Coverage"."Object ID" in [50000 .. 99999] then // free/prototypes range
                        currXMLport.Skip();

                    if SkipTestAndDemoData then
                        if "Code Coverage"."Object ID" in [100000 .. 199999] then // Skip tests, UPTK, demotool
                            currXMLport.Skip();

                    // some CUs with binary data... so skip this ones...
                    // this should be removed when (if) platform UT will be moved to a proper range
                    if ("Code Coverage"."Object ID" = 20003) and
                       ("Code Coverage"."Object Type" = "Code Coverage"."Object Type"::Codeunit)
                    then
                        currXMLport.Skip();

                    IsEmptyLine := 'No';
                    NewOrChanged := 'No';
                    Covered := 'No';
                    LineType := Format("Code Coverage"."Line Type");
                    ObjType := Format("Code Coverage"."Object Type");
                    case "Code Coverage"."Line Type" of
                        "Code Coverage"."Line Type"::Code:
                            begin
                                ChangelistCode.SetRange("Object Type", ChangelistCode.GetObjectType("Code Coverage"));
                                ChangelistCode.SetRange("Object No.", "Code Coverage"."Object ID");
                                ChangelistCode.SetRange("Code Coverage Line No.", "Code Coverage"."Line No.");
                                ChangelistCode.SetRange("Line Type", ChangelistCode."Line Type"::Code);
                                if ChangelistCode.FindFirst() and (ChangelistCode.Change = '+') then
                                    NewOrChanged := 'Yes';
                                if "Code Coverage"."No. of Hits" > 0 then
                                    Covered := 'Yes';
                            end;
                        "Code Coverage"."Line Type"::Object:
                            begin
                                ObjectName := "Code Coverage".Line;
                                currXMLport.Skip();
                            end;
                        "Code Coverage"."Line Type"::"Trigger/Function":
                            begin
                                FunctionName := "Code Coverage".Line;
                                currXMLport.Skip();
                            end;
                        "Code Coverage"."Line Type"::Empty:
                            begin
                                IsEmptyLine := 'Yes';
                                // Skip pure empty lines
                                if DelChr("Code Coverage".Line, ' ', '') = '' then
                                    currXMLport.Skip();
                            end;
                    end;
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
    end;
}

