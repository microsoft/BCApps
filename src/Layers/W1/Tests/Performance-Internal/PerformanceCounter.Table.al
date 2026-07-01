table 130015 "Performance Counter"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Text[250])
        {
        }
        field(2; Value; Duration)
        {
        }
        field(3; "Start Time"; Time)
        {
        }
        field(4; "Count"; Integer)
        {
        }
        field(5; "Min"; Duration)
        {
        }
        field(6; "Max"; Duration)
        {
        }
        field(7; IsValid; Boolean)
        {
            InitValue = true;
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Start(CounterName: Text[250])
    var
        PerformanceCounter: Record "Performance Counter";
    begin
        if not PerformanceCounter.Get(CounterName) then begin
            PerformanceCounter.Init();
            PerformanceCounter.Name := CounterName;
            PerformanceCounter.Insert();
        end;

        PerformanceCounter.IsValid := PerformanceCounter."Start Time" = 0T;

        PerformanceCounter."Start Time" := Time;
        PerformanceCounter.Count := PerformanceCounter.Count + 1;
        PerformanceCounter.Modify();

        Commit();
    end;

    [Scope('OnPrem')]
    procedure Stop(CounterName: Text[250])
    var
        PerformanceCounter: Record "Performance Counter";
        Lap: Duration;
    begin
        if not PerformanceCounter.Get(CounterName) then
            Error('Unknown performance counter: %1.', CounterName);

        PerformanceCounter.IsValid := PerformanceCounter."Start Time" <> 0T;

        Lap := Time - PerformanceCounter."Start Time";

        if Lap > PerformanceCounter.Max then
            PerformanceCounter.Max := Lap;

        if (PerformanceCounter.Min = 0) or (Lap < PerformanceCounter.Min) then
            PerformanceCounter.Min := Lap;

        PerformanceCounter.Value := PerformanceCounter.Value + Lap;
        PerformanceCounter."Start Time" := 0T;
        PerformanceCounter.Modify();

        Commit();
    end;
}

