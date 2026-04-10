namespace System.Automation;

using System.Reflection;

table 1520 "Workflow Event"
{
    Caption = 'Workflow Event';
    LookupPageID = "Workflow Events";
    Permissions = TableData "Workflow Step Argument" = rm;
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
            Caption = 'When';
        }
        field(4; "Request Page ID"; Integer)
        {
            Caption = 'Request Page ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(5; "Dynamic Req. Page Entity Name"; Code[20])
        {
            Caption = 'Dynamic Req. Page Entity Name';
            TableRelation = "Dynamic Request Page Entity".Name where("Table ID" = field("Table ID"));
        }
        field(6; "Used for Record Change"; Boolean)
        {
            Caption = 'Used for Record Change';
        }
        field(7; Independent; Boolean)
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
        WorkflowManagement.ClearSupportedCombinations("Function Name", WFEventResponseCombination.Type::"Event");
    end;

    var
        EventConditionsCaptionTxt: Label 'Event Conditions - %1', Comment = '%1 = Event description';

    [Scope('OnPrem')]
    procedure RunRequestPage(var ReturnFilters: Text; Filters: Text): Boolean
    begin
        if "Request Page ID" > 0 then
            exit(RunCustomRequestPage(ReturnFilters, Filters));

        exit(RunDynamicRequestPage(ReturnFilters, Filters));
    end;

    local procedure RunCustomRequestPage(var ReturnFilters: Text; Filters: Text): Boolean
    begin
        ReturnFilters := REPORT.RunRequestPage("Request Page ID", Filters);

        if ReturnFilters = '' then
            exit(false);

        exit(true);
    end;

    local procedure RunDynamicRequestPage(var ReturnFilters: Text; Filters: Text): Boolean
    var
        TableMetadata: Record "Table Metadata";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
    begin
        if not TableMetadata.Get("Table ID") then
            exit(false);

        if not RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, "Dynamic Req. Page Entity Name", "Table ID") then
            exit(false);

        if Filters <> '' then
            if not RequestPageParametersHelper.SetViewOnDynamicRequestPage(
                 FilterPageBuilder, Filters, "Dynamic Req. Page Entity Name", "Table ID")
            then
                exit(false);

        FilterPageBuilder.PageCaption := StrSubstNo(EventConditionsCaptionTxt, Description);
        if not FilterPageBuilder.RunModal() then
            exit(false);

        ReturnFilters :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, "Dynamic Req. Page Entity Name", "Table ID");

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CreateDefaultRequestPageFilters(): Text
    var
        TableMetadata: Record "Table Metadata";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
    begin
        if not TableMetadata.Get("Table ID") then
            exit('');

        if not RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, "Dynamic Req. Page Entity Name", "Table ID") then
            exit('');

        exit(RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, "Dynamic Req. Page Entity Name", "Table ID"));
    end;

    procedure HasPredecessors(): Boolean
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        WFEventResponseCombination.SetRange(Type, WFEventResponseCombination.Type::"Event");
        WFEventResponseCombination.SetRange("Function Name", "Function Name");
        exit(not WFEventResponseCombination.IsEmpty);
    end;

    procedure MakeDependentOnAllEvents()
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        if WorkflowEvent.FindSet() then
            repeat
                WorkflowEventHandling.AddEventPredecessor("Function Name", WorkflowEvent."Function Name");
            until WorkflowEvent.Next() = 0;
    end;

    procedure MakeIndependent()
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        if not HasPredecessors() then
            exit;

        WFEventResponseCombination.MakeEventResponseIndependent(WFEventResponseCombination.Type::"Event", "Function Name");
    end;
}

