namespace System.AI;

using System.Environment;

table 2023 "Image Analysis Scenario"
{
    Caption = 'Image Analysis Scenario';
    DataPerCompany = false;
    Extensible = false;
    Permissions = tabledata "Image Analysis Scenario" = Rimd;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Scenario Name"; Code[20])
        {
            Caption = 'Scenario Name';
        }
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company;
        }
        field(3; Status; Boolean)
        {
            Caption = 'Status';
        }
    }

    keys
    {
        key(PK; "Scenario Name", "Company Name")
        {
            Clustered = true;
        }
    }

    procedure Enabled(Scenario: Code[20]): Boolean
    var
        Company: Record Company;
        [SecurityFiltering(SecurityFilter::Ignored)]
        ImageAnalysisScenario: Record "Image Analysis Scenario";
    begin
        if Rec.Get(Scenario, CompanyName()) then
            exit(Rec.Status);

        if Rec.Get(Scenario, '') then
            exit(Rec.Status);

        if Company.Get(CompanyName()) and Company."Evaluation Company" and ImageAnalysisScenario.WritePermission() then
            exit(true);

        exit(Rec.Status);
    end;

    procedure EnableAllKnownAllCompanies()
    begin
        EnableAllKnownForCompany('');
    end;

    procedure EnableAllKnownForCompany(Company: Text[20])
    var
        Scenarios: List of [Code[20]];
        Scenario: Code[20];
    begin
        OnGetKnownScenarios(Scenarios);

        Rec.Reset();
        foreach Scenario in Scenarios do begin
            Rec.SetRange("Scenario Name", Scenario);
            Rec.DeleteAll();

            Rec.Init();
            Rec.Validate("Scenario Name", Scenario);
            Rec.Validate("Company Name", Company);
            Rec.Validate(Status, true);
            Rec.Insert(true);
        end;

        Rec.Reset();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetKnownScenarios(var Scenarios: List of [Code[20]])
    begin
    end;
}