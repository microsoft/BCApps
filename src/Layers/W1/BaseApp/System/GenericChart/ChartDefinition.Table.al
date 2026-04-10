namespace System.Visualization;

using Microsoft.Finance.FinancialReports;

table 1310 "Chart Definition"
{
    Caption = 'Chart Definition';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code Unit ID"; Integer)
        {
            Caption = 'Code Unit ID';
        }
        field(2; "Chart Name"; Text[60])
        {
            Caption = 'Chart Name';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            trigger OnValidate()
            begin
                if not Enabled then
                    exit;
                if SupportSetup() then
                    if not IsSetupComplete(Rec) then
                        error(MissingSetuperr);
            end;
        }
    }

    keys
    {
        key(Key1; "Code Unit ID", "Chart Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
    procedure SupportSetup(): Boolean
    begin
        if "Code Unit ID" = CODEUNIT::"Acc. Sched. Chart Management" then
            exit(true);
        exit(false);
    end;

    procedure IsSetupComplete(ChartDefinition: Record "Chart Definition"): Boolean
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        if ChartDefinition."Code Unit ID" <> CODEUNIT::"Acc. Sched. Chart Management" then
            exit(true);
        if not AccountSchedulesChartSetup.get('', ChartDefinition."Chart Name") then
            exit(false);
        if ((AccountSchedulesChartSetup."Account Schedule Name" = '') or (AccountSchedulesChartSetup."Column Layout Name" = '')) then
            exit(false);

        exit(true);
    end;

    var
        MissingSetupErr: Label 'Setup is incomplete.';
}

