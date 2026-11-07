xmlport 130001 "Test Coverage Map"
{
    Direction = Both;
    Format = VariableText;

    schema
    {
        textelement("<coverage>")
        {
            XmlName = 'Coverage';
            tableelement("Test Coverage Map"; "Test Coverage Map")
            {
                AutoUpdate = true;
                XmlName = 'TestCoverageMap';
                fieldelement(TestCodeunitID; "Test Coverage Map"."Test Codeunit ID")
                {
                }
                fieldelement(ObjectType; "Test Coverage Map"."Object Type")
                {
                }
                fieldelement(ObjectID; "Test Coverage Map"."Object ID")
                {
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
}

