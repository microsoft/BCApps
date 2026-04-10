namespace System.Automation;

using System.Reflection;

table 1521 "Workflow Response"
{
    Caption = 'Workflow Response';
    LookupPageID = "Workflow Responses";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Function Name"; Code[128])
        {
            Caption = 'Function Name';
            NotBlank = true;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(3; Description; Text[250])
        {
            Caption = 'Then';
        }
        field(4; "Response Option Group"; Code[20])
        {
            Caption = 'Response Option Group';
            InitValue = 'GROUP 0';
        }
        field(5; Independent; Boolean)
        {
            Caption = 'Independent';
        }
    }

    keys
    {
        key(Key1; "Function Name")
        {
            Clustered = true;
        }
        key(Key2; Independent, Description)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        WorkflowManagement.ClearSupportedCombinations("Function Name", WFEventResponseCombination.Type::Response);
    end;

    procedure HasPredecessors(): Boolean
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        WFEventResponseCombination.SetRange(Type, WFEventResponseCombination.Type::Response);
        WFEventResponseCombination.SetRange("Function Name", "Function Name");
        exit(not WFEventResponseCombination.IsEmpty);
    end;

    procedure MakeDependentOnAllEvents()
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        if WorkflowEvent.FindSet() then
            repeat
                WorkflowResponseHandling.AddResponsePredecessor("Function Name", WorkflowEvent."Function Name");
            until WorkflowEvent.Next() = 0;
    end;

    procedure MakeIndependent()
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        if not HasPredecessors() then
            exit;

        WFEventResponseCombination.MakeEventResponseIndependent(WFEventResponseCombination.Type::Response, "Function Name");
    end;
}

