codeunit 119033 "Create Constrained Capacity"
{

    trigger OnRun()
    begin
        InsertData('120', 1, 90, 5);
    end;

    procedure InsertData(No: Code[20]; Type: Option "Work Center","Machine Center"; CriticalLoadPct: Decimal; DampeningPct: Decimal)
    var
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        ConstrainedCapacity: Record "Capacity Constrained Resource";
    begin
        ConstrainedCapacity.Validate("Capacity Type", Type);
        ConstrainedCapacity.Validate("Capacity No.", No);
        ConstrainedCapacity.Insert();
        case ConstrainedCapacity."Capacity Type" of
            ConstrainedCapacity."Capacity Type"::"Work Center":
                begin
                    WorkCenter.Get(No);
                    ConstrainedCapacity.Name := WorkCenter.Name;
                    ConstrainedCapacity."Work Center No." := WorkCenter."No."
                end;
            ConstrainedCapacity."Capacity Type"::"Machine Center":
                begin
                    MachineCenter.Get(ConstrainedCapacity."Capacity No.");
                    ConstrainedCapacity.Name := MachineCenter.Name;
                    ConstrainedCapacity."Work Center No." := MachineCenter."Work Center No."
                end
        end;
        ConstrainedCapacity.Validate("Critical Load %", CriticalLoadPct);
        ConstrainedCapacity.Validate("Dampener (% of Total Capacity)", DampeningPct);
        ConstrainedCapacity.Modify();
    end;
}

