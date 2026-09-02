enumextension 3304 "Service Integration MX" extends "Service Integration"
{

    value(3300; "Interfactura Service")
    {
        Implementation =
                IDocumentSender = "MX Interfactura Impl.",
                IDocumentReceiver = "MX Interfactura Impl.";

        Caption = 'Interfactura';
    }

}