namespace System.Automation;

table 1507 "Workflow Step Buffer"
{
    Caption = 'Workflow Step Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order"; Integer)
        {
            Caption = 'Order';
            DataClassification = SystemMetadata;
        }
        field(2; Indent; Integer)
        {
            Caption = 'Indent';
            DataClassification = SystemMetadata;
        }
        field(3; "Event Description"; Text[250])
        {
            Caption = 'Event Description';
            DataClassification = SystemMetadata;
            TableRelation = "Workflow Event".Description;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                WorkflowEvent: Record "Workflow Event";
            begin
                LookupEvents('', WorkflowEvent);
            end;

            trigger OnValidate()
            var
                WorkflowEvent: Record "Workflow Event";
                WorkflowStep: Record "Workflow Step";
            begin
                WorkflowEvent.SetRange(Description, "Event Description");
                if not WorkflowEvent.FindFirst() then begin
                    WorkflowEvent.SetFilter(Description, '%1', '@*' + "Event Description" + '*');
                    if not LookupEvents(WorkflowEvent.GetView(), WorkflowEvent) then
                        Error(EventNotExistErr, "Event Description");
                end;

                WorkflowStep.SetRange("Workflow Code", "Workflow Code");
                WorkflowStep.SetRange(ID, "Event Step ID");
                if not WorkflowStep.FindFirst() then begin
                    Insert(true);
                    WorkflowStep.SetRange(ID, "Event Step ID");
                    WorkflowStep.FindFirst();
                end;

                WorkflowStep.Validate("Function Name", WorkflowEvent."Function Name");
                WorkflowStep.Modify(true);

                UpdateCondition(WorkflowStep);
                UpdateThen();
            end;
        }
        field(4; Condition; Text[100])
        {
            Caption = 'Condition';
            DataClassification = SystemMetadata;
        }
        field(5; "Response Description"; Text[250])
        {
            Caption = 'Response Description';
            DataClassification = SystemMetadata;
            TableRelation = "Workflow Response".Description;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                WorkflowResponse: Record "Workflow Response";
                WorkflowStep: Record "Workflow Step";
            begin
                if "Response Description" = '' then begin
                    Delete(true);
                    exit;
                end;

                WorkflowResponse.SetRange(Description, "Response Description");
                if not WorkflowResponse.FindFirst() then begin
                    WorkflowResponse.SetFilter(Description, '%1', '@*' + "Response Description" + '*');
                    if not ResponseDescriptionLookup(WorkflowResponse.GetView(), WorkflowResponse) then
                        Error(ResponseNotExistErr, "Response Description");
                end;

                WorkflowStep.SetRange("Workflow Code", "Workflow Code");
                WorkflowStep.SetRange(ID, "Response Step ID");
                if not WorkflowStep.FindFirst() then begin
                    Insert(true);
                    WorkflowStep.SetRange(ID, "Response Step ID");
                    WorkflowStep.FindFirst();
                end;

                WorkflowStep.Validate("Function Name", WorkflowResponse."Function Name");
                WorkflowStep.Modify(true);
                UpdateRecFromWorkflowStep();
                Modify(true);
            end;
        }
        field(7; "Event Step ID"; Integer)
        {
            Caption = 'Event Step ID';
            DataClassification = SystemMetadata;
            TableRelation = "Workflow Step".ID where("Workflow Code" = field("Workflow Code"),
                                                      Type = const(Event));
        }
        field(8; "Response Step ID"; Integer)
        {
            Caption = 'Response Step ID';
            DataClassification = SystemMetadata;
            TableRelation = "Workflow Step".ID where("Workflow Code" = field("Workflow Code"),
                                                      Type = const(Response));
        }
        field(9; "Workflow Code"; Code[20])
        {
            Caption = 'Workflow Code';
            DataClassification = SystemMetadata;
            TableRelation = Workflow.Code;
        }
        field(10; "Parent Event Step ID"; Integer)
        {
            Caption = 'Parent Event Step ID';
            DataClassification = SystemMetadata;
            TableRelation = "Workflow Step".ID where("Workflow Code" = field("Workflow Code"),
                                                      Type = const(Event));
        }
        field(11; "Previous Workflow Step ID"; Integer)
        {
            Caption = 'Previous Workflow Step ID';
            DataClassification = SystemMetadata;
            TableRelation = "Workflow Step".ID where("Workflow Code" = field("Workflow Code"));
        }
        field(12; "Response Description Style"; Text[30])
        {
            Caption = 'Response Description Style';
            DataClassification = SystemMetadata;
        }
        field(14; "Entry Point"; Boolean)
        {
            Caption = 'Entry Point';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                WorkflowStep: Record "Workflow Step";
            begin
                if not WorkflowStep.Get("Workflow Code", "Event Step ID") then
                    Error(WhenMissingErr);

                WorkflowStep.Validate("Entry Point", "Entry Point");
                WorkflowStep.Modify(true);
            end;
        }
        field(15; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
            DataClassification = SystemMetadata;
        }
        field(16; "Next Step Description"; Text[250])
        {
            Caption = 'Next Step Description';
            DataClassification = SystemMetadata;
        }
        field(17; Argument; Guid)
        {
            Caption = 'Argument';
            DataClassification = SystemMetadata;
        }
        field(18; Template; Boolean)
        {
            CalcFormula = lookup(Workflow.Template where(Code = field("Workflow Code")));
            Caption = 'Template';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Order")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        if "Response Step ID" > 0 then begin
            WorkflowStep.Get("Workflow Code", "Response Step ID");
            WorkflowStep.Delete(true);
        end;

        if "Response Step ID" = MultipleResponseID() then begin
            TempWorkflowStepBuffer.PopulateTableFromEvent("Workflow Code", "Event Step ID");
            TempWorkflowStepBuffer.DeleteAll(true);
        end;

        if "Event Step ID" > 0 then begin
            WorkflowStep.Get("Workflow Code", "Event Step ID");
            WorkflowStep.Delete(true);
        end;
    end;

    trigger OnInsert()
    var
        WorkflowStep: Record "Workflow Step";
        IsEventInsert: Boolean;
    begin
        IsEventInsert := "Parent Event Step ID" = 0;

        if "Previous Workflow Step ID" = 0 then
            CreateWorkflowStep(WorkflowStep, "Workflow Code", "Parent Event Step ID")
        else
            CreateWorkflowStep(WorkflowStep, "Workflow Code", "Previous Workflow Step ID");

        if IsEventInsert then begin
            WorkflowStep.Validate(Type, WorkflowStep.Type::"Event");
            WorkflowStep.Validate("Entry Point", "Entry Point");
            WorkflowStep.Validate("Sequence No.", "Sequence No.");
            WorkflowStep.Modify(true);
            UpdateCondition(WorkflowStep);
            UpdateSequenceNo();
            "Event Step ID" := WorkflowStep.ID;
        end else begin
            if "Previous Workflow Step ID" = 0 then
                "Previous Workflow Step ID" := "Parent Event Step ID";
            ChangeChildsPreviousToMe("Workflow Code", "Previous Workflow Step ID", WorkflowStep.ID);
            WorkflowStep.Validate(Type, WorkflowStep.Type::Response);
            WorkflowStep.Modify(true);
            "Response Step ID" := WorkflowStep.ID;
        end;
    end;

    trigger OnModify()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        if not WorkflowStep.Get("Workflow Code", "Event Step ID") then
            exit;

        WorkflowStep.Validate("Previous Workflow Step ID", "Previous Workflow Step ID");
        WorkflowStep.Validate("Sequence No.", "Sequence No.");
        WorkflowStep.Modify(true);
    end;

    var
#pragma warning disable AA0470
        ThenTextForMultipleResponsesTxt: Label '(+) %1';
#pragma warning restore AA0470
        SelectResponseTxt: Label '<Select Response>';
        EventNotExistErr: Label 'The workflow event %1 does not exist.', Comment = '%1 = event description (e.g. The workflow event A general journal batch is does not exist.)';
        WhenMissingErr: Label 'You must select a When statement first.';
        ResponseNotExistErr: Label 'The workflow response %1 does not exist.', Comment = '%1 = response description (e.g. The workflow response Remove record does not exist.)';
#pragma warning disable AA0470
        WhenNextStepDescTxt: Label 'Next when "%1"';
        ThenNextStepDescTxt: Label 'Next then "%1"';
#pragma warning restore AA0470
        ResponseDeleteLbl: Label 'You are about to change the "When Event". This change will cause the "On Condition" and the "Then Responses" to be deleted. Do you want to continue?';

    [Scope('OnPrem')]
    procedure OpenEventConditions()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
    begin
        Workflow.Get("Workflow Code");
        WorkflowStep.Get(Workflow.Code, "Event Step ID");
        WorkflowEvent.Get(WorkflowStep."Function Name");

        if WorkflowEvent."Used for Record Change" then
            WorkflowStep.OpenAdvancedEventConditions()
        else
            WorkflowStep.OpenEventConditions();

        UpdateCondition(WorkflowStep);
    end;

    [Scope('OnPrem')]
    procedure DeleteEventConditions()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.Get("Workflow Code", "Event Step ID");
        WorkflowStep.DeleteEventConditions();
        UpdateCondition(WorkflowStep);
    end;

    procedure OpenEventResponses()
    var
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        TempWorkflowStepBuffer.PopulateTableFromEvent("Workflow Code", "Event Step ID");
        if PAGE.RunModal(PAGE::"Workflow Step Responses", TempWorkflowStepBuffer) = ACTION::LookupOK then;
        UpdateThen();
    end;

    [Scope('OnPrem')]
    procedure PopulateTable(WorkflowCode: Code[20])
    var
        OrderVar: Integer;
    begin
        OrderVar := 10000;
        CreateTree(WorkflowCode, OrderVar, 0, 0, false);
        if FindSet() then;
    end;

    local procedure CreateTree(WorkflowCode: Code[20]; var OrderVar: Integer; NodeId: Integer; CurrIndent: Integer; ForLookup: Boolean)
    var
        WorkflowStep: Record "Workflow Step";
    begin
        if NodeId <> 0 then
            CreateNode(WorkflowCode, OrderVar, NodeId, CurrIndent, ForLookup);

        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        WorkflowStep.SetRange("Previous Workflow Step ID", NodeId);
        WorkflowStep.SetCurrentKey("Sequence No.");

        if not WorkflowStep.FindSet() then
            exit;

        repeat
            CreateTree(WorkflowCode, OrderVar, WorkflowStep.ID, CurrIndent, ForLookup);
        until WorkflowStep.Next() = 0;
    end;

    local procedure CreateNode(WorkflowCode: Code[20]; var OrderVar: Integer; var NodeID: Integer; var CurrIndent: Integer; ForLookup: Boolean)
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.Get(WorkflowCode, NodeID);
        CreateWhen(WorkflowCode, OrderVar, CurrIndent, WorkflowStep);
        if ForLookup then
            NodeID := CreateResponseTree(WorkflowCode, OrderVar, NodeID)
        else
            NodeID := UpdateThen();
    end;

    local procedure UpdateThen(): Integer
    var
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        LastThen: Text[250];
    begin
        TempWorkflowStepBuffer.PopulateTableFromEvent("Workflow Code", "Event Step ID");
        if TempWorkflowStepBuffer.FindFirst() then;
        case TempWorkflowStepBuffer.Count of
            0:
                begin
                    "Response Description" := SelectResponseTxt;
                    "Response Step ID" := 0;
                end;
            1:
                begin
                    "Response Description" := TempWorkflowStepBuffer."Response Description";
                    "Response Step ID" := TempWorkflowStepBuffer."Response Step ID";
                end;
            else begin
                LastThen := CopyStr(TempWorkflowStepBuffer."Response Description", 1,
                    MaxStrLen(TempWorkflowStepBuffer."Response Description") - StrLen(ThenTextForMultipleResponsesTxt));
                "Response Description" := StrSubstNo(ThenTextForMultipleResponsesTxt, LastThen);
                "Response Step ID" := MultipleResponseID();
            end;
        end;

        UpdateResponseDescriptionStyle();

        Modify();

        if TempWorkflowStepBuffer.FindLast() then
            exit(TempWorkflowStepBuffer."Response Step ID");

        exit("Event Step ID")
    end;

    procedure PopulateTableFromEvent(WorkflowCode: Code[20]; WorkflowEventID: Integer)
    var
        OrderVar: Integer;
    begin
        SetRange("Workflow Code", WorkflowCode);
        SetRange("Parent Event Step ID", WorkflowEventID);
        OrderVar := 10000;
        CreateResponseTree(WorkflowCode, OrderVar, WorkflowEventID);
        if FindSet() then;
    end;

    local procedure CreateResponseTree(WorkflowCode: Code[20]; var OrderVar: Integer; NodeId: Integer): Integer
    var
        WorkflowStep: Record "Workflow Step";
        ParentEventStepID: Integer;
    begin
        ParentEventStepID := NodeId;

        repeat
            WorkflowStep.SetRange("Workflow Code", WorkflowCode);
            WorkflowStep.SetRange("Previous Workflow Step ID", NodeId);

            if not WorkflowStep.FindFirst() then
                exit(NodeId);

            if WorkflowStep.Type <> WorkflowStep.Type::Response then
                exit(NodeId);

            CreateResponseNode(WorkflowCode, OrderVar, WorkflowStep, ParentEventStepID);

            NodeId := WorkflowStep.ID;
        until false;
    end;

    local procedure CreateResponseNode(WorkflowCode: Code[20]; var OrderVar: Integer; WorkflowStep: Record "Workflow Step"; ParentEventStepID: Integer)
    begin
        Init();
        "Workflow Code" := WorkflowCode;
        Order := OrderVar;
        OrderVar += 10000;
        "Parent Event Step ID" := ParentEventStepID;
        "Response Step ID" := WorkflowStep.ID;
        UpdateRecFromWorkflowStep();
        UpdateNextStepDescription();
        Insert();
    end;

    procedure ClearBuffer()
    var
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        TempWorkflowStepBuffer.Copy(Rec, true);
        TempWorkflowStepBuffer.Reset();
        TempWorkflowStepBuffer.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure PopulateLookupTable(WorkflowCode: Code[20])
    var
        OrderVar: Integer;
    begin
        OrderVar := 10000;
        CreateTree(WorkflowCode, OrderVar, 0, 0, true);
        if FindSet() then;
    end;

    local procedure CreateWorkflowStep(var WorkflowStep: Record "Workflow Step"; WorkflowCode: Code[20]; PreviousStepID: Integer)
    begin
        WorkflowStep.Init();
        WorkflowStep.Validate("Workflow Code", WorkflowCode);
        WorkflowStep.Insert(true);

        WorkflowStep.Validate("Previous Workflow Step ID", PreviousStepID);
        WorkflowStep.Modify(true);
    end;

    local procedure ChangeChildsPreviousToMe(WorkflowCode: Code[20]; CurrentPreviousID: Integer; NewPreviousID: Integer)
    var
        ChildWorkflowStep: Record "Workflow Step";
    begin
        if CurrentPreviousID <> 0 then begin
            ChildWorkflowStep.SetRange("Workflow Code", WorkflowCode);
            ChildWorkflowStep.SetRange("Previous Workflow Step ID", CurrentPreviousID);
            ChildWorkflowStep.SetFilter(ID, StrSubstNo('<>%1', NewPreviousID));
            if ChildWorkflowStep.FindSet(true) then
                repeat
                    ChildWorkflowStep.Validate("Previous Workflow Step ID", NewPreviousID);
                    ChildWorkflowStep.Modify(true);
                until ChildWorkflowStep.Next() <> 1;
        end;
    end;

    local procedure MultipleResponseID(): Integer
    begin
        exit(-1);
    end;

    procedure UpdateResponseDescriptionStyle()
    begin
        if "Response Step ID" = MultipleResponseID() then
            "Response Description Style" := 'StandardAccent'
        else
            "Response Description Style" := 'Standard';
    end;

    local procedure CreateWhen(WorkflowCode: Code[20]; var OrderVar: Integer; var CurrIndent: Integer; WorkflowStep: Record "Workflow Step")
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        Init();
        "Workflow Code" := WorkflowCode;
        Order := OrderVar;
        OrderVar += 10000;
        "Event Step ID" := WorkflowStep.ID;
        if WorkflowEvent.Get(WorkflowStep."Function Name") then
            "Event Description" := WorkflowEvent.Description;
        "Previous Workflow Step ID" := WorkflowStep."Previous Workflow Step ID";
        UpdateCondition(WorkflowStep);
        "Entry Point" := WorkflowStep."Entry Point";
        "Sequence No." := WorkflowStep."Sequence No.";
        Indent := CurrIndent;
        CurrIndent += 1;
        Insert();
    end;

    procedure CalculateNewKey(BelowxRec: Boolean)
    var
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        TempWorkflowStepBuffer.Copy(Rec, true);
        if BelowxRec then begin
            if TempWorkflowStepBuffer.FindLast() then;
            Order := TempWorkflowStepBuffer.Order + 10000;
        end else begin
            TempWorkflowStepBuffer.SetFilter(Order, '<%1', xRec.Order);
            if TempWorkflowStepBuffer.FindLast() then;
            Order := Round((xRec.Order - TempWorkflowStepBuffer.Order) / 2, 1) + TempWorkflowStepBuffer.Order;
        end;
    end;

    procedure CreateNewWhenThenLine(WorkflowCode: Code[20]; BelowxRec: Boolean)
    begin
        if xRec.Find() then begin
            "Previous Workflow Step ID" := xRec."Previous Workflow Step ID";
            Indent := xRec.Indent;
            "Sequence No." := xRec."Sequence No.";
        end;

        "Workflow Code" := WorkflowCode;

        CalculateNewKey(BelowxRec);
    end;

    local procedure UpdateCondition(WorkflowStep: Record "Workflow Step")
    var
        WorkflowMgt: Codeunit "Workflow Management";
    begin
        WorkflowStep.Find();
        Condition := WorkflowMgt.BuildConditionDisplay(WorkflowStep);
    end;

    procedure SetxRec(TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary)
    begin
        xRec := TempWorkflowStepBuffer;
    end;

    local procedure UpdateSequenceNo()
    var
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowStep: Record "Workflow Step";
        i: Integer;
    begin
        TempWorkflowStepBuffer.Copy(Rec, true);
        TempWorkflowStepBuffer.SetRange("Previous Workflow Step ID", "Previous Workflow Step ID");
        TempWorkflowStepBuffer.SetFilter("Sequence No.", '>=%1', "Sequence No.");

        if not TempWorkflowStepBuffer.FindSet() then
            exit;

        i := "Sequence No.";
        repeat
            i += 1;
            WorkflowStep.Get(TempWorkflowStepBuffer."Workflow Code", TempWorkflowStepBuffer."Event Step ID");
            WorkflowStep.Validate("Sequence No.", i);
            WorkflowStep.Modify(true);
        until TempWorkflowStepBuffer.Next() = 0;
    end;

    procedure MoveLeft()
    var
        TempSiblingWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        ParentEventWorkflowStep: Record "Workflow Step";
        CurrentWorkflowStep: Record "Workflow Step";
        NewParentWorkflowStep: Record "Workflow Step";
        ChildEventWorkflowStep: Record "Workflow Step";
    begin
        CurrentWorkflowStep.Get("Workflow Code", "Event Step ID");
        if CurrentWorkflowStep.HasEventsInSubtree(ChildEventWorkflowStep) then
            exit;

        if not FindParentEvent(CurrentWorkflowStep, ParentEventWorkflowStep) then
            exit;

        FindSiblingEvents(TempSiblingWorkflowStepBuffer);
        TempSiblingWorkflowStepBuffer.SetFilter(Order, '>%1', Order);
        if FindLastResponseDescendant(CurrentWorkflowStep, NewParentWorkflowStep) then
            TempSiblingWorkflowStepBuffer.ModifyAll("Previous Workflow Step ID", NewParentWorkflowStep.ID, true)
        else
            TempSiblingWorkflowStepBuffer.ModifyAll("Previous Workflow Step ID", CurrentWorkflowStep.ID, true);

        CurrentWorkflowStep.Validate("Previous Workflow Step ID", ParentEventWorkflowStep."Previous Workflow Step ID");
        CurrentWorkflowStep.Modify(true);

        "Previous Workflow Step ID" := CurrentWorkflowStep."Previous Workflow Step ID";
        Indent -= 1;
        Modify();

        UpdateSequenceNo();
    end;

    procedure MoveRight()
    var
        TempSiblingWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        ParentEventWorkflowStep: Record "Workflow Step";
        NewParentWorkflowStep: Record "Workflow Step";
        CurrentWorkflowStep: Record "Workflow Step";
    begin
        CurrentWorkflowStep.Get("Workflow Code", "Event Step ID");

        if UpdateSubtree(CurrentWorkflowStep) then
            exit;

        FindSiblingEvents(TempSiblingWorkflowStepBuffer);
        TempSiblingWorkflowStepBuffer.SetFilter(Order, '<%1', Order);
        if not TempSiblingWorkflowStepBuffer.FindLast() then
            exit;

        ParentEventWorkflowStep.Get(TempSiblingWorkflowStepBuffer."Workflow Code", TempSiblingWorkflowStepBuffer."Event Step ID");
        if FindLastResponseDescendant(ParentEventWorkflowStep, NewParentWorkflowStep) then
            CurrentWorkflowStep.Validate("Previous Workflow Step ID", NewParentWorkflowStep.ID)
        else
            CurrentWorkflowStep.Validate("Previous Workflow Step ID", ParentEventWorkflowStep.ID);
        CurrentWorkflowStep.Modify(true);

        "Previous Workflow Step ID" := CurrentWorkflowStep."Previous Workflow Step ID";
        Indent := TempSiblingWorkflowStepBuffer.Indent + 1;
        Modify();

        UpdateSequenceNo();
    end;

    local procedure UpdateSubtree(var CurrentWorkflowStep: Record "Workflow Step"): Boolean
    var
        ChildEventWorkflowStep: Record "Workflow Step";
        ParentEventWorkflowStep: Record "Workflow Step";
        NewParentWorkflowStep: Record "Workflow Step";
        NewParentStepID: Integer;
    begin
        if not CurrentWorkflowStep.HasEventsInSubtree(ChildEventWorkflowStep) then
            exit(false);

        if FindParentEvent(CurrentWorkflowStep, ParentEventWorkflowStep) then
            exit(false);

        if not FindPreviousRootEvent(Rec, ParentEventWorkflowStep) then
            exit(false);

        if FindLastResponseDescendant(ParentEventWorkflowStep, NewParentWorkflowStep) then
            NewParentStepID := NewParentWorkflowStep.ID
        else
            NewParentStepID := ParentEventWorkflowStep.ID;

        repeat
            ChildEventWorkflowStep.Validate("Previous Workflow Step ID", NewParentStepID);
            ChildEventWorkflowStep.Modify(true);
        until not CurrentWorkflowStep.HasEventsInSubtree(ChildEventWorkflowStep);

        Indent += 1;
        Modify();

        CurrentWorkflowStep.Validate("Previous Workflow Step ID", NewParentStepID);
        CurrentWorkflowStep.Modify(true);

        exit(true);
    end;

    local procedure FindLastResponseDescendant(ParentWorkflowStep: Record "Workflow Step"; var WorkflowStep: Record "Workflow Step"): Boolean
    var
        ChildWorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetCurrentKey("Sequence No.");
        WorkflowStep.SetRange("Workflow Code", ParentWorkflowStep."Workflow Code");
        WorkflowStep.SetRange("Previous Workflow Step ID", ParentWorkflowStep.ID);
        WorkflowStep.SetRange(Type, ParentWorkflowStep.Type::Response);
        if WorkflowStep.FindLast() then begin
            ChildWorkflowStep.Init();
            if FindLastResponseDescendant(WorkflowStep, ChildWorkflowStep) then
                WorkflowStep := ChildWorkflowStep;
            exit(true);
        end;

        exit(false);
    end;

    local procedure FindParentEvent(WorkflowStep: Record "Workflow Step"; var ParentEventWorkflowStep: Record "Workflow Step"): Boolean
    var
        PreviousWorkflowStep: Record "Workflow Step";
    begin
        if not PreviousWorkflowStep.Get(WorkflowStep."Workflow Code", WorkflowStep."Previous Workflow Step ID") then
            exit(false);

        case PreviousWorkflowStep.Type of
            PreviousWorkflowStep.Type::"Event":
                begin
                    ParentEventWorkflowStep := PreviousWorkflowStep;
                    exit(true);
                end;
            PreviousWorkflowStep.Type::Response:
                exit(FindParentEvent(PreviousWorkflowStep, ParentEventWorkflowStep));
        end;
    end;

    local procedure FindSiblingEvents(var TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary)
    begin
        TempWorkflowStepBuffer.Copy(Rec, true);
        Clear(TempWorkflowStepBuffer);
        TempWorkflowStepBuffer.SetCurrentKey("Sequence No.");
        TempWorkflowStepBuffer.SetRange("Workflow Code", "Workflow Code");
        TempWorkflowStepBuffer.SetRange("Previous Workflow Step ID", "Previous Workflow Step ID");
        TempWorkflowStepBuffer.SetRange(Indent, Indent);
    end;

    local procedure FindPreviousRootEvent(WorkflowStepBuffer: Record "Workflow Step Buffer"; var RootWorkflowStep: Record "Workflow Step"): Boolean
    var
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        FindSiblingEvents(TempWorkflowStepBuffer);
        TempWorkflowStepBuffer.SetRange("Previous Workflow Step ID", 0);
        TempWorkflowStepBuffer.SetFilter(Order, '<%1', WorkflowStepBuffer.Order);
        if TempWorkflowStepBuffer.FindLast() then
            exit(RootWorkflowStep.Get(TempWorkflowStepBuffer."Workflow Code", TempWorkflowStepBuffer."Event Step ID"));
    end;

    procedure UpdateNextStepDescription()
    var
        NextStepWorkflowStep: Record "Workflow Step";
        WorkflowStep: Record "Workflow Step";
    begin
        GetWorkflowStep(WorkflowStep);

        if NextStepWorkflowStep.Get(WorkflowStep."Workflow Code", WorkflowStep."Next Workflow Step ID") then
            case NextStepWorkflowStep.Type of
                NextStepWorkflowStep.Type::"Event":
                    "Next Step Description" := StrSubstNo(WhenNextStepDescTxt, NextStepWorkflowStep.GetDescription());
                NextStepWorkflowStep.Type::Response:
                    "Next Step Description" := StrSubstNo(ThenNextStepDescTxt, NextStepWorkflowStep.GetDescription());
            end
        else
            "Next Step Description" := '';
    end;

    procedure GetWorkflowStep(var WorkflowStep: Record "Workflow Step"): Boolean
    begin
        exit(WorkflowStep.Get("Workflow Code", "Event Step ID" + "Response Step ID"));
    end;

    [Scope('OnPrem')]
    procedure NextStepLookup(): Boolean
    var
        WorkflowStep: Record "Workflow Step";
    begin
        if GetWorkflowStep(WorkflowStep) then
            if WorkflowStep.LookupOtherWorkflowStepID(WorkflowStep."Next Workflow Step ID") then begin
                WorkflowStep.Validate("Next Workflow Step ID");
                WorkflowStep.Modify(true);
                UpdateNextStepDescription();
                exit(true);
            end;

        exit(false);
    end;

    procedure ResponseDescriptionLookup(ResponseFilter: Text; var WorkflowResponse: Record "Workflow Response"): Boolean
    var
        WorkflowStep: Record "Workflow Step";
        TempWorkflowResponse: Record "Workflow Response" temporary;
    begin
        WorkflowStep.Get("Workflow Code", "Parent Event Step ID");
        FindSupportedResponses(WorkflowStep."Function Name", TempWorkflowResponse);
        FindIndependentResponses(TempWorkflowResponse);

        TempWorkflowResponse.SetView(ResponseFilter);
        if PAGE.RunModal(PAGE::"Workflow Responses", TempWorkflowResponse) = ACTION::LookupOK then begin
            if not WorkflowStep.Get("Workflow Code", "Response Step ID") then begin
                Insert(true);
                WorkflowStep.Get("Workflow Code", "Response Step ID");
            end;

            WorkflowStep.Validate("Function Name", TempWorkflowResponse."Function Name");
            WorkflowStep.Modify(true);

            "Response Description" := TempWorkflowResponse.Description;
            WorkflowResponse.Get(TempWorkflowResponse."Function Name");

            exit(true);
        end;
        exit(false);
    end;

    procedure UpdateRecFromWorkflowStep()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        if not GetWorkflowStep(WorkflowStep) then
            exit;

        "Response Description" := WorkflowStep.GetDescription();
        "Previous Workflow Step ID" := WorkflowStep."Previous Workflow Step ID";
        Argument := WorkflowStep.Argument;
    end;

    local procedure LookupEvents(EventFilter: Text; var WorkflowEvent: Record "Workflow Event"): Boolean
    var
        WorkflowStep: Record "Workflow Step";
        ParentEventWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        TempWorkflowEvent: Record "Workflow Event" temporary;
    begin
        if WorkflowStep.Get("Workflow Code", "Event Step ID") then
            FindParentEvent(WorkflowStep, ParentEventWorkflowStep)
        else begin
            TempWorkflowStepBuffer.Copy(Rec, true);
            TempWorkflowStepBuffer.SetRange("Workflow Code", "Workflow Code");
            TempWorkflowStepBuffer.SetFilter(Order, '<%1', Order);
            if Indent > 0 then
                TempWorkflowStepBuffer.SetFilter(Indent, '<%1', Indent);
            if TempWorkflowStepBuffer.FindLast() then
                ParentEventWorkflowStep.Get(TempWorkflowStepBuffer."Workflow Code", TempWorkflowStepBuffer."Event Step ID");
        end;

        FindSupportedEvents(ParentEventWorkflowStep."Function Name", TempWorkflowEvent);

        FindIndependentEvents(TempWorkflowEvent);

        TempWorkflowEvent.SetView(EventFilter);
        if PAGE.RunModal(0, TempWorkflowEvent) = ACTION::LookupOK then begin
            if ("Event Description" <> '') and ("Event Description" <> TempWorkflowEvent.Description) then
                if Dialog.Confirm(ResponseDeleteLbl, false) then
                    DeleteResponse()
                else
                    exit(false);

            Validate("Event Description", TempWorkflowEvent.Description);
            WorkflowEvent.Get(TempWorkflowEvent."Function Name");
            exit(true);
        end;
        exit(false);
    end;

    local procedure FindSupportedEvents(PredecessorFunctionName: Code[128]; var TempWorkflowEvent: Record "Workflow Event" temporary)
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowEvent: Record "Workflow Event";
    begin
        WFEventResponseCombination.SetRange(Type, WFEventResponseCombination.Type::"Event");
        WFEventResponseCombination.SetRange("Predecessor Type", WFEventResponseCombination."Predecessor Type"::"Event");
        WFEventResponseCombination.SetRange("Predecessor Function Name", PredecessorFunctionName);
        if WFEventResponseCombination.FindSet() then
            repeat
                if WorkflowEvent.Get(WFEventResponseCombination."Function Name") then begin
                    TempWorkflowEvent := WorkflowEvent;
                    TempWorkflowEvent.Independent := false;
                    if TempWorkflowEvent.Insert() then;
                end;
            until WFEventResponseCombination.Next() = 0;
    end;

    local procedure FindSupportedResponses(PredecessorFunctionName: Code[128]; var TempWorkflowResponse: Record "Workflow Response" temporary)
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowResponse: Record "Workflow Response";
    begin
        WFEventResponseCombination.SetRange(Type, WFEventResponseCombination.Type::Response);
        WFEventResponseCombination.SetRange("Predecessor Type", WFEventResponseCombination."Predecessor Type"::"Event");
        WFEventResponseCombination.SetRange("Predecessor Function Name", PredecessorFunctionName);
        if WFEventResponseCombination.FindSet() then
            repeat
                if WorkflowResponse.Get(WFEventResponseCombination."Function Name") then begin
                    TempWorkflowResponse := WorkflowResponse;
                    TempWorkflowResponse.Independent := false;
                    if TempWorkflowResponse.Insert() then;
                end;
            until WFEventResponseCombination.Next() = 0;
    end;

    local procedure FindIndependentEvents(var TempWorkflowEvent: Record "Workflow Event" temporary)
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        if WorkflowEvent.FindSet() then
            repeat
                if not WorkflowEvent.HasPredecessors() then begin
                    TempWorkflowEvent := WorkflowEvent;
                    TempWorkflowEvent.Independent := true;
                    if TempWorkflowEvent.Insert() then;
                end;
            until WorkflowEvent.Next() = 0;
    end;

    local procedure FindIndependentResponses(var TempWorkflowResponse: Record "Workflow Response" temporary)
    var
        WorkflowResponse: Record "Workflow Response";
    begin
        if WorkflowResponse.FindSet() then
            repeat
                if not WorkflowResponse.HasPredecessors() then begin
                    TempWorkflowResponse := WorkflowResponse;
                    TempWorkflowResponse.Independent := true;
                    if TempWorkflowResponse.Insert() then;
                end;
            until WorkflowResponse.Next() = 0;
    end;

    local procedure DeleteResponse()
    var
        WorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        if "Response Step ID" > 0 then begin
            WorkflowStep.Get("Workflow Code", "Response Step ID");
            WorkflowStep.Delete(true);
        end;

        if "Response Step ID" = MultipleResponseID() then begin
            TempWorkflowStepBuffer.PopulateTableFromEvent("Workflow Code", "Event Step ID");
            TempWorkflowStepBuffer.DeleteAll(true);
        end;
    end;
}

