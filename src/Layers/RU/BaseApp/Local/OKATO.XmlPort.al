#pragma warning disable AA0247
xmlport 12427 OKATO
{
    Caption = 'OKATO';

    schema
    {
        textelement(OKATOCodes)
        {
            tableelement(OKATO; OKATO)
            {
                AutoUpdate = true;
                XmlName = 'OKATO';
                fieldelement(Code; OKATO.Code)
                {
                }
                fieldelement(Name; OKATO.Name)
                {
                }
                fieldelement(RegionCode; OKATO."Region Code")
                {
                }
                fieldelement(TaxAuthorityNo; OKATO."Tax Authority No.")
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

