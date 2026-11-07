xmlport 130004 "Code Base Lines"
{
    Direction = Export;
    Format = VariableText;

    schema
    {
        textelement(CoverageData)
        {
            tableelement("Code Coverage"; "Code Coverage")
            {
                XmlName = 'CodeCoverage';
                SourceTableView = sorting("Object Type", "Object ID", "Line No.") order(ascending);
                fieldelement(ObjectType; "Code Coverage"."Object Type")
                {
                }
                fieldelement(ObjectID; "Code Coverage"."Object ID")
                {
                }
                fieldelement(LineNo; "Code Coverage"."Line No.")
                {
                }
                fieldelement(LineType; "Code Coverage"."Line Type")
                {
                }
                textelement(Change)
                {
                }
                fieldelement(Line; "Code Coverage".Line)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if (("Code Coverage"."Object ID" >= 130000) and ("Code Coverage"."Object ID" <= 149999)) or // test range
                       (("Code Coverage"."Object ID" >= 103000) and ("Code Coverage"."Object ID" <= 103999)) // costing suite
                    then
                        currXMLport.Skip();

                    Change := '0';
                    if "Code Coverage"."Line Type" = "Code Coverage"."Line Type"::Code then begin
                        ChangelistCode.SetRange("Object Type", ChangelistCode.GetObjectType("Code Coverage"));
                        ChangelistCode.SetRange("Object No.", "Code Coverage"."Object ID");
                        ChangelistCode.SetRange("Code Coverage Line No.", "Code Coverage"."Line No.");
                        ChangelistCode.SetRange("Line Type", ChangelistCode."Line Type"::Code);
                        if ChangelistCode.FindFirst() and (ChangelistCode.Change = '+') then
                            Change := '1';
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
}

