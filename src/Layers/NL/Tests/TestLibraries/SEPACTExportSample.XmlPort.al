xmlport 144055 "SEPA CT Export Sample"
{
    Direction = Export;

    schema
    {
        tableelement("Gen. Journal Line"; "Gen. Journal Line")
        {
            XmlName = 'Document';
            UseTemporary = true;
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
        Message('XMLPort144055 [%1]', "Gen. Journal Line".GetFilters);
        Error('');
    end;
}

