xmlport 130029 "Import Code Cov. Test Results"
{
    Direction = Import;
    Format = VariableText;

    schema
    {
        textelement(root)
        {
            tableelement("Code Coverage"; "Code Coverage")
            {
                AutoSave = true;
                AutoUpdate = false;
                RequestFilterFields = "Object ID";
                XmlName = 'CodeCoverage';
                fieldelement(ObjectType; "Code Coverage"."Object Type")
                {
                }
                fieldelement(ObjectNo; "Code Coverage"."Object ID")
                {
                }
                fieldelement(LineNo; "Code Coverage"."Line No.")
                {
                }
                fieldelement(NoOfHits; "Code Coverage"."No. of Hits")
                {
                    MaxOccurs = Once;
                }
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

    trigger OnPostXmlPort()
    begin
        Commit();
    end;

    trigger OnPreXmlPort()
    begin
        "Code Coverage".SetFilter("Object ID", '..99999|200000..');
        AllObj.SetFilter("Object ID", "Code Coverage".GetFilter("Object ID"));

        CodeCoverageLog(true, true);
        CodeCoverageInclude(AllObj);
        CodeCoverageLog(false, true);
    end;

    var
        AllObj: Record AllObj;
}

