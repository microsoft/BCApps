xmlport 101905 "Post Codes Demo Data"
{
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = ';';
    Format = VariableText;
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement("Post Code"; "Post Code")
            {
                XmlName = 'PostCodes';
                fieldelement(code; "Post Code".Code)
                {
                }
                fieldelement(city; "Post Code".City)
                {
                    MinOccurs = Zero;
                }
                fieldelement(country; "Post Code"."Country/Region Code")
                {
                }
                fieldelement(county; "Post Code".County)
                {
                    MinOccurs = Zero;
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

