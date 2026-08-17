codeunit 118846 "Create Dist. Whse. Filter"
{

    trigger OnRun()
    begin
        InsertData(1, XDHL_FILTER, XFiltersforShippingagentDHL, XDHL, '', '');
        InsertData(1, XOWNLOG, XTransOrdwithOwnLogistics, '', XOWN_LOG, '');
        InsertData(1, XCUSTOMERS, XAllcustomers, '', '', '1..999999');
    end;

    var
        XDHL_FILTER: Label 'DHL_FILTER';
        XFiltersforShippingagentDHL: Label 'Filters for Shipping agent DHL';
        XDHL: Label 'DHL';
        XOWNLOG: Label 'OWNLOG';
        XTransOrdwithOwnLogistics: Label 'Trans. Ord. with Own Logistics';
        XOWN_LOG: Label 'OWN LOG.';
        XCUSTOMERS: Label 'CUSTOMERS';
        XAllcustomers: Label 'All customers';

    procedure InsertData(Type: Option; "Code": Code[10]; Description: Text[30]; ShipAgentCodeFilter: Code[100]; InTransitCodeFilter: Code[100]; SellToCustFilter: Code[100])
    var
        WhseSourceFilter: Record "Warehouse Source Filter";
    begin
        WhseSourceFilter.Init();
        WhseSourceFilter.Validate(Type, Type);
        WhseSourceFilter.Validate(Code, Code);
        WhseSourceFilter.Validate(Description, Description);
        WhseSourceFilter.Validate("Shipping Agent Code Filter", ShipAgentCodeFilter);
        WhseSourceFilter.Validate("In-Transit Code Filter", InTransitCodeFilter);
        WhseSourceFilter.Validate("Sell-to Customer No. Filter", SellToCustFilter);
        WhseSourceFilter.Insert(true);
    end;
}

