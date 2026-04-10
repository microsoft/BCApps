namespace System.Automation;

table 1509 "WF Event/Response Combination"
{
    Caption = 'WF Event/Response Combination';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Event,Response';
            OptionMembers = "Event",Response;
        }
        field(2; "Function Name"; Code[128])
        {
            Caption = 'Function Name';
            TableRelation = if (Type = const(Event)) "Workflow Event"
            else
            if (Type = const(Response)) "Workflow Response";
        }
        field(3; "Predecessor Type"; Option)
        {
            Caption = 'Predecessor Type';
            OptionCaption = 'Event,Response';
            OptionMembers = "Event",Response;
        }
        field(4; "Predecessor Function Name"; Code[128])
        {
            Caption = 'Predecessor Function Name';
            TableRelation = if ("Predecessor Type" = const(Event)) "Workflow Event"
            else
            if ("Predecessor Type" = const(Response)) "Workflow Response";
        }
    }

    keys
    {
        key(Key1; Type, "Function Name", "Predecessor Type", "Predecessor Function Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure MakeEventResponseIndependent(Type: Option; FunctionName: Code[128])
    var
        WorkflowEvent: Record "Workflow Event";
        WFEventResponseCombination: Record "WF Event/Response Combination";
        IsDependentOnAllEvents: Boolean;
    begin
        IsDependentOnAllEvents := true;
        if WorkflowEvent.FindSet() then
            repeat
                if not WFEventResponseCombination.Get(Type, FunctionName,
                     WFEventResponseCombination.Type::"Event", WorkflowEvent."Function Name")
                then
                    IsDependentOnAllEvents := false;
            until (WorkflowEvent.Next() = 0) or (not IsDependentOnAllEvents);

        if IsDependentOnAllEvents then begin
            WFEventResponseCombination.SetRange(Type, Type);
            WFEventResponseCombination.SetRange("Function Name", FunctionName);
            if not WFEventResponseCombination.IsEmpty() then
                WFEventResponseCombination.DeleteAll();
        end;
    end;
}

