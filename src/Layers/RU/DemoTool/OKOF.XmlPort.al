xmlport 163406 OKOF
{
    Caption = 'OKOF';

    schema
    {
        textelement(OKOFElements)
        {
            tableelement("Depreciation Code"; "Depreciation Code")
            {
                XmlName = 'OKOF';
                fieldelement(CodeType; "Depreciation Code"."Code Type")
                {
                }
                fieldelement(Indentation; "Depreciation Code".Indentation)
                {
                }
                fieldelement(Parent; "Depreciation Code".Parent)
                {
                }
                fieldelement(Code; "Depreciation Code".Code)
                {
                }
                fieldelement(Name; "Depreciation Code".Name)
                {
                }
                fieldelement(CheckNumber; "Depreciation Code"."Check Number")
                {
                }
                fieldelement(DepreciationGroup; "Depreciation Code"."Depreciation Group")
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

