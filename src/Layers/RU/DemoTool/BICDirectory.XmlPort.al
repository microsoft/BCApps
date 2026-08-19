xmlport 163403 "BIC Directory"
{
    Caption = 'BIC Directory';

    schema
    {
        textelement(BICDirectoryElements)
        {
            tableelement("Bank Directory"; "Bank Directory")
            {
                XmlName = 'BICDirectory';
                fieldelement(BIC; "Bank Directory".BIC)
                {
                }
                fieldelement(CorrAccountNo; "Bank Directory"."Corr. Account No.")
                {
                }
                fieldelement(ShortName; "Bank Directory"."Short Name")
                {
                }
                fieldelement(FullName; "Bank Directory"."Full Name")
                {
                }
                fieldelement(RegionCode; "Bank Directory"."Region Code")
                {
                }
                fieldelement(PostCode; "Bank Directory"."Post Code")
                {
                }
                fieldelement(AreaType; "Bank Directory"."Area Type")
                {
                }
                fieldelement(AreaName; "Bank Directory"."Area Name")
                {
                }
                fieldelement(Address; "Bank Directory".Address)
                {
                }
                fieldelement(Telephone; "Bank Directory".Telephone)
                {
                }
                fieldelement(OKPO; "Bank Directory".OKPO)
                {
                }
                fieldelement(RegistrationNo; "Bank Directory"."Registration No.")
                {
                }
                fieldelement(RKC; "Bank Directory".RKC)
                {
                }
                fieldelement(Type; "Bank Directory".Type)
                {
                }
                fieldelement(LastModifyDate; "Bank Directory"."Last Modify Date")
                {
                }
                fieldelement(Status; "Bank Directory".Status)
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

