namespace System.TestTools.CodeCoverage;
using System.Tooling;

xmlport 9990 "Code Coverage Summary"
{
    Caption = 'Code Coverage Summary';
    Direction = Export;

    schema
    {
        textelement("<coverage>")
        {
            XmlName = 'Coverage';
            tableelement("Code Coverage"; "Code Coverage")
            {
                XmlName = 'CodeCoverageObjects';
                SourceTableView = sorting("Object Type", "Object ID", "Line No.") order(ascending);
                fieldelement(LineType; "Code Coverage"."Line Type")
                {
                }
                fieldelement(ObjectType; "Code Coverage"."Object Type")
                {
                }
                fieldelement(ObjectID; "Code Coverage"."Object ID")
                {
                }
                textelement(ObjectName)
                {
                }
                textelement(LinesHit)
                {
                }
                textelement(Lines)
                {
                }
                textelement("<objectcoverage>")
                {
                    XmlName = 'Coverage';
                }

                trigger OnAfterGetRecord()
                var
                    TotalLines: Integer;
                    HitLines: Integer;
                begin
                    case "Code Coverage"."Line Type" of
                        "Code Coverage"."Line Type"::Object:
                            begin
                                ObjectName := "Code Coverage".Line;

                                "<ObjectCoverage>" := Format(CodeCoverageMgt.ObjectCoverage("Code Coverage", TotalLines, HitLines));
                            end;
                        "Code Coverage"."Line Type"::"Trigger/Function":
                            begin
                                ObjectName := "Code Coverage".Line;

                                "<ObjectCoverage>" := Format(CodeCoverageMgt.FunctionCoverage("Code Coverage", TotalLines, HitLines));
                            end;
                        else
                            currXMLport.Skip();
                    end;

                    LinesHit := Format(HitLines);
                    Lines := Format(TotalLines);
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

    var
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
}

