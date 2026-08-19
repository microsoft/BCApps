xmlport 101904 "Currency Demo Data"
{
    DefaultFieldsValidation = false;
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = ';';
    Format = VariableText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(tempcurrencydata; "Temporary Currency Data")
            {
                XmlName = 'TempCurrencyData';
                fieldelement(cc; TempCurrencyData."Currency Code")
                {
                }
                fieldelement(ISONumericCode; TempCurrencyData."ISO Numeric Code")
                {
                }
                textelement(localprecisionfactor)
                {
                    MinOccurs = Zero;
                    XmlName = 'LocPrec';

                    trigger OnAfterAssignVariable()
                    begin
                        Evaluate(TempCurrencyData."Local Precision Factor", LocalPrecisionFactor, 9);
                    end;
                }
                textelement(amountroundingprecision)
                {
                    MinOccurs = Zero;
                    XmlName = 'AmtRndPrec';

                    trigger OnAfterAssignVariable()
                    begin
                        Evaluate(TempCurrencyData."Amount Rounding Precision", AmountRoundingPrecision, 9);
                    end;
                }
                textelement(unitamountroundingprecision)
                {
                    MinOccurs = Zero;
                    XmlName = 'UAmtRndPrec';

                    trigger OnAfterAssignVariable()
                    begin
                        Evaluate(TempCurrencyData."Unit-Amount Rounding Precision", UnitAmountRoundingPrecision, 9);
                    end;
                }
                textelement(invoiceroundingprecision)
                {
                    MinOccurs = Zero;
                    XmlName = 'InvRndPred';

                    trigger OnAfterAssignVariable()
                    begin
                        Evaluate(TempCurrencyData."Invoice Rounding Precision", InvoiceRoundingPrecision, 9);
                    end;
                }
                fieldelement(InvRndType; TempCurrencyData."Invoice Rounding Type")
                {
                    MinOccurs = Zero;
                }
                fieldelement(XRateAmt; TempCurrencyData."Exchange Rate Amount")
                {
                    MinOccurs = Zero;
                }
                textelement(relationalexchrateamount)
                {
                    MinOccurs = Zero;
                    XmlName = 'RelXRateAmt';

                    trigger OnAfterAssignVariable()
                    begin
                        Evaluate(TempCurrencyData."Relational Exch. Rate Amount", RelationalExchRateAmount, 9);
                    end;
                }
                fieldelement(EMUCC; TempCurrencyData."EMU Currency")
                {
                    MinOccurs = Zero;
                }
                fieldelement(AmtDecPl; TempCurrencyData."Amount Decimal Places")
                {
                    MinOccurs = Zero;
                }
                fieldelement(UAmtDecPl; TempCurrencyData."Unit-Amount Decimal Places")
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

