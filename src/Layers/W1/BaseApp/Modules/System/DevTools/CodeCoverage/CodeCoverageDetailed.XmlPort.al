namespace System.TestTools.CodeCoverage;

using System.Reflection;
using System.Tooling;

xmlport 9991 "Code Coverage Detailed"
{
    Caption = 'Code Coverage Detailed';
    Format = VariableText;

    schema
    {
        textelement(Coverage)
        {
            tableelement("Code Coverage"; "Code Coverage")
            {
                XmlName = 'CodeCoverage';
                SourceTableView = where("Line Type" = const(Code), "No. of Hits" = filter(> 0));
                fieldelement(ObjectType; "Code Coverage"."Object Type")
                {
                }
                fieldelement(ObjectID; "Code Coverage"."Object ID")
                {
                }
                fieldelement(LineNo; "Code Coverage"."Line No.")
                {
                }
                fieldelement(Hits; "Code Coverage"."No. of Hits")
                {
                }

                trigger OnBeforeInsertRecord()
                var
                    AllObj: Record AllObj;
                begin
                    "Code Coverage"."Line Type" := "Code Coverage"."Line Type"::Code;
                    if not AllObj.Get("Code Coverage"."Object Type", "Code Coverage"."Object ID") then
                        currXMLport.Skip();
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

    trigger OnInitXmlPort()
    begin
        currXMLport.ImportFile := false;
    end;

    trigger OnPostXmlPort()
    begin
        if currXMLport.ImportFile then
            CodeCoverageMgt.Import();
    end;

    trigger OnPreXmlPort()
    begin
        if currXMLport.ImportFile then begin
            "Code Coverage".Reset();
            CodeCoverageMgt.Clear();
        end;
    end;

    var
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
}

