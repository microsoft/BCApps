/// <summary>
/// A code coverage xmlport inspired from "Code Coverage Detailed" defined in the Base Application
/// that is used internally for the integration with AzureDevOps code coverage.
/// </summary>
xmlport 130007 "Code Coverage Internal"
{
    Caption = 'Code Coverage Detailed Internal';
    Format = VariableText;

    schema
    {
        textelement(Coverage)
        {
            tableelement("Code Coverage"; "Code Coverage")
            {
                XmlName = 'CodeCoverage';
                SourceTableView = where("Line Type" = Const(Code));

                fieldelement(ObjectType; "Code Coverage"."Object Type")
                {
                }
                fieldelement(ObjectID; "Code Coverage"."Object ID")
                {
                }
                fieldelement(LineNo; "Code Coverage"."Line No.")
                {
                }
                textelement(CoverageStatus)
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

                trigger OnAfterGetRecord()
                begin
                    // Adjust the "Code Coverage Status" for AzureDevOps
                    case "Code Coverage"."Code Coverage Status" of
                        "Code Coverage"."Code Coverage Status"::Covered:
                            CoverageStatus := AzureDevOpsCovered;
                        "Code Coverage"."Code Coverage Status"::NotCovered:
                            CoverageStatus := AzureDevOpsNotCovered;
                        "Code Coverage"."Code Coverage Status"::PartiallyCovered:
                            CoverageStatus := AzureDevOpsPartiallyCovered;
                    end;
                end;
            }
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
        AzureDevOpsCovered: Label '0', Locked = true;
        AzureDevOpsNotCovered: Label '1', Locked = true;
        AzureDevOpsPartiallyCovered: Label '2', Locked = true;
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
}