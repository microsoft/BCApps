// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Visualization;

table 763 "Acc. Sched. Chart Setup Line"
{
    Caption = 'Acc. Sched. Chart Setup Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Account Schedules Chart Setup"."User ID" where(Name = field(Name));
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
            Editable = false;
            TableRelation = "Account Schedules Chart Setup".Name where("User ID" = field("User ID"));
        }
        field(3; "Account Schedule Name"; Code[10])
        {
            Caption = 'Account Schedule Name';
            Editable = false;
            TableRelation = "Acc. Schedule Name".Name;
        }
        field(4; "Account Schedule Line No."; Integer)
        {
            Caption = 'Account Schedule Line No.';
            Editable = false;
            TableRelation = "Acc. Schedule Line"."Line No." where("Schedule Name" = field("Account Schedule Name"));
        }
        field(5; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Layout Name';
            Editable = false;
            TableRelation = "Column Layout Name".Name;
        }
        field(6; "Column Layout Line No."; Integer)
        {
            Caption = 'Column Layout Line No.';
            Editable = false;
            TableRelation = "Column Layout"."Line No." where("Column Layout Name" = field("Column Layout Name"));
        }
        field(10; "Original Measure Name"; Text[111])
        {
            Caption = 'Original Measure Name';
            Editable = false;
        }
        field(15; "Measure Name"; Text[111])
        {
            Caption = 'Measure Name';

            trigger OnValidate()
            begin
                TestField("Measure Name");
            end;
        }
        field(20; "Measure Value"; Text[30])
        {
            Caption = 'Measure Value';
            Editable = false;
        }
        field(40; "Chart Type"; Enum "Account Schedule Chart Type")
        {
            Caption = 'Chart Type';

            trigger OnValidate()
            var
                AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
                AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
                BusinessChartBuffer: Record "Business Chart Buffer";
                ActualNumMeasures: Integer;
            begin
                if ("Chart Type" <> "Chart Type"::" ") and IsMeasure() then begin
                    AccountSchedulesChartSetup.Get("User ID", Name);
                    AccountSchedulesChartSetup.SetLinkToMeasureLines(AccSchedChartSetupLine);
                    AccSchedChartSetupLine.SetFilter("Chart Type", '<>%1', AccSchedChartSetupLine."Chart Type"::" ");
                    ActualNumMeasures := 0;
                    if AccSchedChartSetupLine.FindSet() then
                        repeat
                            if (AccSchedChartSetupLine."Account Schedule Line No." <> "Account Schedule Line No.") or
                               (AccSchedChartSetupLine."Column Layout Line No." <> "Column Layout Line No.")
                            then
                                ActualNumMeasures += 1;
                        until AccSchedChartSetupLine.Next() = 0;
                    if ActualNumMeasures >= BusinessChartBuffer.GetMaxNumberOfMeasures() then
                        BusinessChartBuffer.RaiseErrorMaxNumberOfMeasuresExceeded();
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "User ID", Name, "Account Schedule Line No.", "Column Layout Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure IsMeasure() Result: Boolean
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        AccountSchedulesChartSetup.Get("User ID", Name);
        case AccountSchedulesChartSetup."Base X-Axis on" of
            AccountSchedulesChartSetup."Base X-Axis on"::Period:
                Result := true;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line":
                if "Account Schedule Line No." = 0 then
                    Result := true;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                if "Column Layout Line No." = 0 then
                    Result := true;
        end;
    end;

    procedure GetDefaultAccSchedChartType(): Enum "Account Schedule Chart Type"
    begin
        exit("Chart Type"::Column);
    end;
}

