xmlport 163401 KBK
{
    Caption = 'KBK';

    schema
    {
        textelement(KBKElements)
        {
            tableelement(KBK; KBK)
            {
                XmlName = 'KBK';
                fieldelement(Code; KBK.Code)
                {
                }
                fieldelement(Name1; KBK."Name 1")
                {
                }
                fieldelement(Name2; KBK."Name 2")
                {
                }
                fieldelement(Name3; KBK."Name 3")
                {
                }
                fieldelement(Indentation; KBK.Indentation)
                {
                }
                fieldelement(Header; KBK.Header)
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

