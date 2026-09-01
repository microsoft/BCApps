xmlport 101899 "Demo Data Configuration"
{
    Encoding = UTF8;
    Format = Xml;

    schema
    {
        tableelement("Demo Data Setup"; "Demo Data Setup")
        {
            XmlName = 'DemoDataSetup';
            fieldelement(StartingYear; "Demo Data Setup"."Starting Year")
            {
            }
            fieldelement(CompanyType; "Demo Data Setup"."Company Type")
            {
            }
            fieldelement(AdvancedSetup; "Demo Data Setup"."Advanced Setup")
            {
            }
            fieldelement(AdjustForPaymentDiscount; "Demo Data Setup"."Adjust for Payment Discount")
            {
            }
            fieldelement(DataLanguageID; "Demo Data Setup"."Data Language ID")
            {
            }
            fieldelement(CountryCode; "Demo Data Setup"."Country/Region Code")
            {
            }
            fieldelement(CurrencyCode; "Demo Data Setup"."Currency Code")
            {
            }
            fieldelement(AdditionalCurrency; "Demo Data Setup"."Additional Currency Code")
            {
            }
            fieldelement(RemoveCountryPrefix; "Demo Data Setup"."Remove Country Prefix")
            {
            }
            fieldelement(DataType; "Demo Data Setup"."Data Type")
            {
            }
            fieldelement(SetupFinancials; "Demo Data Setup".Financials)
            {
            }
            fieldelement(SetupRelationshipMgt; "Demo Data Setup"."Relationship Mgt.")
            {
            }
            fieldelement(SetupServiceMgt; "Demo Data Setup"."Service Management")
            {
            }
            fieldelement(SetupDistribution; "Demo Data Setup".Distribution)
            {
            }
            fieldelement(SetupManufacturing; "Demo Data Setup".Manufacturing)
            {
            }
            fieldelement(SetupADCS; "Demo Data Setup".ADCS)
            {
            }
            fieldelement(TestDemonstrationCompany; "Demo Data Setup"."Test Demonstration Company")
            {
            }
            fieldelement(RapidStartCountry; "Demo Data Setup"."Rapid Start Country")
            {
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

    procedure ConfigLanguageID(): Integer
    begin
        exit(1033);
    end;

    procedure ConfigFileName(IsMini: Boolean): Text[30]
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        if DemoDataSetup.Get() then;
        if IsMini then
            exit(DemoDataSetup."Path to Picture Folder" + 'MiniDemoDataConfig.xml');

        exit(DemoDataSetup."Path to Picture Folder" + 'DemoDataConfig.xml');
    end;
}

