codeunit 118601 "Setup API Endpoints"
{

    trigger OnRun()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        GraphMgtGeneralTools.ApiSetup();
    end;
}

