// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

table 959 "Time Sheet Chart Setup"
{
    Caption = 'Time Sheet Chart Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(3; "Show by"; Option)
        {
            Caption = 'Show by';
            OptionCaption = 'Status,Type,Posted';
            OptionMembers = Status,Type,Posted;
        }
        field(4; "Measure Type"; Option)
        {
            Caption = 'Measure Type';
            OptionCaption = 'Open,Submitted,Rejected,Approved,Scheduled,Posted,Not Posted,Resource,Project,Service,Absence,Assembly Order';
            OptionMembers = Open,Submitted,Rejected,Approved,Scheduled,Posted,"Not Posted",Resource,Job,Service,Absence,"Assembly Order";
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Period: %1..%2 | Show by: %3 | Updated: %4.', Comment = 'Period: (date)..(date) | show by (Status or Posted) | updated (time).';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure GetCurrentSelectionText(): Text[250]
    begin
        exit(StrSubstNo(Text001, "Starting Date", GetEndingDate(), "Show by", Time));
    end;

    procedure SetStartingDate(StartingDate: Date)
    begin
        "Starting Date" := StartingDate;
        Modify();
    end;

    procedure GetEndingDate(): Date
    begin
        exit(CalcDate('<1W>', "Starting Date") - 1);
    end;

    procedure FindPeriod(Which: Option Previous,Next)
    begin
        case Which of
            Which::Previous:
                "Starting Date" := CalcDate('<-1W>', "Starting Date");
            Which::Next:
                "Starting Date" := CalcDate('<+1W>', "Starting Date");
        end;
        Modify();
    end;

    procedure SetShowBy(ShowBy: Option)
    begin
        "Show by" := ShowBy;
        Modify();
    end;

    procedure MeasureIndex2MeasureType(MeasureIndex: Integer): Integer
    begin
        case "Show by" of
            "Show by"::Status:
                exit(MeasureIndex);
            "Show by"::Posted:
                case MeasureIndex of
                    0:
                        exit("Measure Type"::Posted);
                    1:
                        exit("Measure Type"::"Not Posted");
                    2:
                        exit("Measure Type"::Scheduled);
                end;
            "Show by"::Type:
                begin
                    if MeasureIndex = 5 then
                        exit("Measure Type"::Scheduled);
                    exit(MeasureIndex + 7);
                end;
        end;
    end;
}

