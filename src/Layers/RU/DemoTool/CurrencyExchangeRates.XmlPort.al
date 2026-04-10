xmlport 163405 "Currency Exchange Rates"
{
    Caption = 'Currency Exchange Rates';

    schema
    {
        textelement(CurrencyExchangeRates)
        {
            tableelement("Currency Exchange Rate"; "Currency Exchange Rate")
            {
                XmlName = 'ExchRate';
                fieldelement(CurrencyCode; "Currency Exchange Rate"."Currency Code")
                {
                }
                fieldelement(StartingDate; "Currency Exchange Rate"."Starting Date")
                {
                }
                fieldelement(ExchRateAmount; "Currency Exchange Rate"."Exchange Rate Amount")
                {
                }
                fieldelement(RelExchRateAmount; "Currency Exchange Rate"."Relational Exch. Rate Amount")
                {
                }
                fieldelement(AdjExchRateAmount; "Currency Exchange Rate"."Adjustment Exch. Rate Amount")
                {
                }
                fieldelement(RelAdjExchRateAmount; "Currency Exchange Rate"."Relational Adjmt Exch Rate Amt")
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

