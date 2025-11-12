// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Utilities;

table 5093 "Opportunity Entry"
{
    Caption = 'Opportunity Entry';
    DataClassification = CustomerContent;
    DrillDownPageID = "Opportunity Entries";
    LookupPageID = "Opportunity Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;

            trigger OnValidate()
            var
                OpportunityEntry2: Record "Opportunity Entry";
            begin
                OpportunityEntry2.SetCurrentKey(Active, "Opportunity No.");
                OpportunityEntry2.SetRange(Active, true);
                OpportunityEntry2.SetRange("Opportunity No.", "Opportunity No.");
                if OpportunityEntry2.FindFirst() then begin
                    "Estimated Value (LCY)" := OpportunityEntry2."Estimated Value (LCY)";
                    "Chances of Success %" := OpportunityEntry2."Chances of Success %";
                    "Date of Change" := OpportunityEntry2."Date of Change";
                    if OpportunityEntry2."Date of Change" > WorkDate() then
                        "Date of Change" := OpportunityEntry2."Date of Change"
                    else
                        "Date of Change" := WorkDate();
                    "Estimated Close Date" := OpportunityEntry2."Estimated Close Date";
                    "Previous Sales Cycle Stage" := OpportunityEntry2."Sales Cycle Stage";
                    "Action Taken" := OpportunityEntry2."Action Taken";
                end else
                    "Date of Change" := WorkDate();
            end;
        }
        field(3; "Sales Cycle Code"; Code[10])
        {
            Caption = 'Sales Cycle Code';
            TableRelation = "Sales Cycle";
        }
        field(4; "Sales Cycle Stage"; Integer)
        {
            Caption = 'Sales Cycle Stage';
            MinValue = 1;
            TableRelation = "Sales Cycle Stage".Stage where("Sales Cycle Code" = field("Sales Cycle Code"));

            trigger OnValidate()
            begin
                if SalesCycleStage.Get("Sales Cycle Code", "Sales Cycle Stage") then
                    "Sales Cycle Stage Description" := SalesCycleStage.Description;
            end;
        }
        field(5; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;
        }
        field(6; "Contact Company No."; Code[20])
        {
            Caption = 'Contact Company No.';
            TableRelation = Contact where(Type = const(Company));
        }
        field(7; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(8; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(9; "Date of Change"; Date)
        {
            Caption = 'Date of Change';
        }
        field(10; Active; Boolean)
        {
            Caption = 'Active';
        }
        field(11; "Date Closed"; Date)
        {
            Caption = 'Date Closed';
        }
        field(12; "Days Open"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Days Open';
            DecimalPlaces = 0 : 0;
            MinValue = 0;
        }
        field(13; "Action Taken"; Enum "Opportunity Action Taken")
        {
            Caption = 'Action Taken';

            trigger OnValidate()
            begin
                if "Action Taken" <> xRec."Action Taken" then
                    Clear("Close Opportunity Code");
            end;
        }
        field(14; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Estimated Value (LCY)';
        }
        field(15; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Calcd. Current Value (LCY)';
        }
        field(16; "Completed %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Completed %';
            DecimalPlaces = 0 : 0;
        }
        field(17; "Chances of Success %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Chances of Success %';
            DecimalPlaces = 0 : 0;
            MaxValue = 100;
        }
        field(18; "Probability %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Probability %';
            DecimalPlaces = 0 : 0;
        }
        field(19; "Close Opportunity Code"; Code[10])
        {
            Caption = 'Close Opportunity Code';
            TableRelation = if ("Action Taken" = const(Won)) "Close Opportunity Code" where(Type = const(Won))
            else
            if ("Action Taken" = const(Lost)) "Close Opportunity Code" where(Type = const(Lost));
        }
        field(20; "Previous Sales Cycle Stage"; Integer)
        {
            Caption = 'Previous Sales Cycle Stage';
            TableRelation = "Sales Cycle Stage".Stage where("Sales Cycle Code" = field("Sales Cycle Code"));
        }
        field(21; "Estimated Close Date"; Date)
        {
            Caption = 'Estimated Close Date';
        }
        field(9501; "Wizard Step"; Option)
        {
            Caption = 'Wizard Step';
            Editable = false;
            OptionCaption = ' ,1,2,3,4,5,6';
            OptionMembers = " ","1","2","3","4","5","6";
        }
        field(9502; "Cancel Old To Do"; Boolean)
        {
            Caption = 'Cancel Old Task';
        }
        field(9503; "Action Type"; Option)
        {
            Caption = 'Action Type';
            OptionCaption = ' ,First,Next,Previous,Skip,Update,Jump';
            OptionMembers = " ",First,Next,Previous,Skip,Update,Jump;
        }
        field(9504; "Sales Cycle Stage Description"; Text[100])
        {
            Caption = 'Sales Cycle Stage Description';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Opportunity No.")
        {
        }
        key(Key3; "Contact Company No.", "Contact No.", Active)
        {
            SumIndexFields = "Estimated Value (LCY)", "Calcd. Current Value (LCY)";
        }
        key(Key4; "Campaign No.", Active)
        {
            SumIndexFields = "Estimated Value (LCY)", "Calcd. Current Value (LCY)";
        }
        key(Key5; Active, "Sales Cycle Code", "Sales Cycle Stage", "Estimated Close Date")
        {
            SumIndexFields = "Estimated Value (LCY)", "Calcd. Current Value (LCY)", "Days Open";
        }
        key(Key6; Active, "Opportunity No.")
        {
            SumIndexFields = "Estimated Value (LCY)", "Calcd. Current Value (LCY)", "Days Open";
        }
        key(Key7; Active, "Salesperson Code", "Date of Change")
        {
            SumIndexFields = "Estimated Value (LCY)", "Calcd. Current Value (LCY)";
        }
        key(Key8; "Close Opportunity Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Opportunity No.", Active)
        {
        }
        fieldgroup(Brick; "Opportunity No.", "Sales Cycle Stage Description")
        {
        }
    }

    trigger OnInsert()
    var
        Opportunity: Record Opportunity;
        SalesCycleStage2: Record "Sales Cycle Stage";
        ShouldModifyOpportunity: Boolean;
    begin
        Opportunity.Get("Opportunity No.");
        case "Action Taken" of
            "Action Taken"::" ",
            "Action Taken"::Next,
            "Action Taken"::Previous,
            "Action Taken"::Updated,
            "Action Taken"::Jumped:
                begin
                    SalesCycleStage2.SetLoadFields(Description);
                    if SalesCycleStage2.Get("Sales Cycle Code", "Sales Cycle Stage") then
                        "Sales Cycle Stage Description" := SalesCycleStage2.Description;
                    if Opportunity.Status <> Opportunity.Status::"In Progress" then begin
                        Opportunity.Status := Opportunity.Status::"In Progress";
                        ShouldModifyOpportunity := true;
                    end;
                end;
            "Action Taken"::Won:
                begin
                    TestCust();
                    if Opportunity.Status <> Opportunity.Status::Won then begin
                        Opportunity.Status := Opportunity.Status::Won;
                        Opportunity.Closed := true;
                        Opportunity."Date Closed" := "Date of Change";
                        "Date Closed" := "Date of Change";
                        "Estimated Close Date" := "Date of Change";
                        ShouldModifyOpportunity := true;
                    end;
                end;
            "Action Taken"::Lost:
                if Opportunity.Status <> Opportunity.Status::Lost then begin
                    Opportunity.Status := Opportunity.Status::Lost;
                    Opportunity.Closed := true;
                    Opportunity."Date Closed" := "Date of Change";
                    "Date Closed" := "Date of Change";
                    "Estimated Close Date" := "Date of Change";
                    ShouldModifyOpportunity := true;
                end;
        end;

        OnOnInsertOnBeforeModifyOpportunity(Rec, Opportunity, ShouldModifyOpportunity);
        if ShouldModifyOpportunity then
            Opportunity.Modify();
    end;

    var
        OpportunityEntry: Record "Opportunity Entry";
        SalesCycleStage: Record "Sales Cycle Stage";
        PreviousDateOfChange: Date;
        EntryExists: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You can not create a Customer from contact %1 before you assign a Contact Company No. to the contact.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'You cannot go to this stage before you have assigned a sales quote.';
#pragma warning disable AA0470
        Text006: Label 'There are no stages in sales cycle %1.';
#pragma warning restore AA0470
        Text007: Label 'The Date of Change has to be after last Date of change.';
#pragma warning disable AA0470
        Text008: Label '%1 must be greater than 0.';
#pragma warning restore AA0470
        Text009: Label 'The Estimated closing date has to be later than this change.';
        Text011: Label 'You must select either Won or Lost.';
        Text012: Label 'Sales (LCY) must be greater than 0.';
#pragma warning disable AA0470
        Text013: Label 'You must fill in the %1 field.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        TempSalesCycleStageFirst: Record "Sales Cycle Stage" temporary;
        TempSalesCycleStageNext: Record "Sales Cycle Stage" temporary;
        TempSalesCycleStagePrevious: Record "Sales Cycle Stage" temporary;
        TempSalesCycleStageSkip: Record "Sales Cycle Stage" temporary;
        TempSalesCycleStageUpdate: Record "Sales Cycle Stage" temporary;
        TempSalesCycleStageJump: Record "Sales Cycle Stage" temporary;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure InsertEntry(var OpportunityEntryToInsert: Record "Opportunity Entry"; CancelOldTask: Boolean; CreateNewTask: Boolean)
    var
        OpportunityEntryInserted: Record "Opportunity Entry";
        EntryNo: Integer;
    begin
        EntryNo := OpportunityEntryInserted.GetLastEntryNo();
        OpportunityEntryInserted.SetCurrentKey(Active, "Opportunity No.");
        OpportunityEntryInserted.SetRange(Active, true);
        OpportunityEntryInserted.SetRange("Opportunity No.", OpportunityEntryToInsert."Opportunity No.");
        if OpportunityEntryInserted.FindFirst() then begin
            OpportunityEntryInserted.Active := false;
            OpportunityEntryInserted."Days Open" := OpportunityEntryToInsert."Date of Change" - OpportunityEntryInserted."Date of Change";
            OpportunityEntryInserted.Modify();
        end;

        OpportunityEntryInserted := OpportunityEntryToInsert;
        OpportunityEntryInserted."Entry No." := EntryNo + 1;
        OpportunityEntryInserted.Active := true;
        OpportunityEntryInserted.CreateTask(CancelOldTask, CreateNewTask);
        OnInsertEntryOnBeforeInsert(OpportunityEntryToInsert, OpportunityEntryInserted);
        OpportunityEntryInserted.Insert(true);
        OpportunityEntryToInsert := OpportunityEntryInserted;
        OnAfterInsertEntry(OpportunityEntryToInsert);
    end;

    procedure UpdateEstimates()
    var
        SalesCycle: Record "Sales Cycle";
        SalesCycleStage2: Record "Sales Cycle Stage";
        Opportunity: Record Opportunity;
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateEstimates(Rec, IsHandled);
        if IsHandled then
            exit;

        SalesCycleStage2.SetLoadFields("Chances of Success %", "Completed %", "Date Formula");
        if SalesCycleStage2.Get("Sales Cycle Code", "Sales Cycle Stage") then begin
            SalesCycle.Get("Sales Cycle Code");
            if ("Chances of Success %" = 0) and (SalesCycleStage2."Chances of Success %" <> 0) then
                "Chances of Success %" := SalesCycleStage2."Chances of Success %";
            "Completed %" := SalesCycleStage2."Completed %";
            case SalesCycle."Probability Calculation" of
                SalesCycle."Probability Calculation"::Multiply:
                    "Probability %" := "Chances of Success %" * "Completed %" / 100;
                SalesCycle."Probability Calculation"::Add:
                    "Probability %" := ("Chances of Success %" + "Completed %") / 2;
                SalesCycle."Probability Calculation"::"Chances of Success %":
                    "Probability %" := "Chances of Success %";
                SalesCycle."Probability Calculation"::"Completed %":
                    "Probability %" := "Completed %";
            end;
            "Calcd. Current Value (LCY)" := "Estimated Value (LCY)" * "Probability %" / 100;
            if ("Estimated Close Date" = "Date of Change") or ("Estimated Close Date" = 0D) then
                "Estimated Close Date" := CalcDate(SalesCycleStage2."Date Formula", "Date of Change");
        end;

        case "Action Taken" of
            "Action Taken"::Won:
                begin
                    Opportunity.Get("Opportunity No.");
                    if SalesHeader.Get(SalesHeader."Document Type"::Quote, Opportunity."Sales Document No.") then
                        "Calcd. Current Value (LCY)" := GetSalesDocValue(SalesHeader);

                    "Completed %" := 100;
                    "Chances of Success %" := 100;
                    "Probability %" := 100;
                end;
            "Action Taken"::Lost:
                begin
                    "Calcd. Current Value (LCY)" := 0;
                    "Completed %" := 100;
                    "Chances of Success %" := 0;
                    "Probability %" := 0;
                end;
        end;

        OnUpdateEstimatesOnBeforeModifyOpportunityEntry(Rec, SalesHeader);
        Modify();
    end;

    procedure CreateTask(CancelOldTask: Boolean; CreateNewTask: Boolean)
    var
        SalesCycleStage2: Record "Sales Cycle Stage";
        ToDoTask: Record "To-do";
        Opportunity: Record Opportunity;
        TempRMCommentLine: Record "Rlshp. Mgt. Comment Line" temporary;
        TempAttendee: Record Attendee temporary;
        TempTaskInteractionLanguage: Record "To-do Interaction Language" temporary;
        TempAttachment: Record Attachment temporary;
    begin
        if CancelOldTask then
            ToDoTask.CancelOpenTasks("Opportunity No.");

        if CreateNewTask then
            if SalesCycleStage2.Get("Sales Cycle Code", "Sales Cycle Stage") then
                if SalesCycleStage2."Activity Code" <> '' then begin
                    Opportunity.Get("Opportunity No.");
                    ToDoTask."No." := '';
                    ToDoTask."Campaign No." := "Campaign No.";
                    ToDoTask."Segment No." := Opportunity."Segment No.";
                    ToDoTask."Salesperson Code" := "Salesperson Code";
                    ToDoTask.Validate("Contact No.", "Contact No.");
                    ToDoTask."Opportunity No." := "Opportunity No.";
                    ToDoTask."Opportunity Entry No." := "Entry No.";
                    ToDoTask.Date := "Date of Change";
                    ToDoTask.Duration := 1440 * 1000 * 60;
                    OnCreateTaskOnBeforeInsertTask(Rec, ToDoTask);
                    ToDoTask.InsertTask(
                      ToDoTask, TempRMCommentLine, TempAttendee,
                      TempTaskInteractionLanguage, TempAttachment,
                      SalesCycleStage2."Activity Code", false);
                end;
    end;

    procedure GetSalesDocValue(SalesHeader: Record "Sales Header") Result: Decimal
    var
        TotalSalesLine: Record "Sales Line";
        TotalSalesLineLCY: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        VATAmount: Decimal;
        VATAmountText: Text[30];
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        TotalAdjCostLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesDocValue(SalesHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        SalesPost.SumSalesLines(
          SalesHeader, 0, TotalSalesLine, TotalSalesLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);
        exit(TotalSalesLineLCY.Amount);
    end;

    local procedure TestCust()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestCust(Rec, IsHandled);
        if IsHandled then
            exit;

        Contact.Get("Contact No.");

        if (Contact.Type = Contact.Type::Person) and (Contact."Company No." <> '') then
            if not Contact.Get(Contact."Company No.") then
                Error(Text000, Contact."No.");

        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);

        if ContactBusinessRelation.IsEmpty() then
            Contact.CreateCustomerFromTemplate('');
    end;

    procedure InitOpportunityEntry(Opportunity: Record Opportunity)
    begin
        Validate("Opportunity No.", Opportunity."No.");
        "Sales Cycle Code" := Opportunity."Sales Cycle Code";
        "Contact No." := Opportunity."Contact No.";
        "Contact Company No." := Opportunity."Contact Company No.";
        "Salesperson Code" := Opportunity."Salesperson Code";
        "Campaign No." := Opportunity."Campaign No.";

        OnAfterInitOpportunityEntry(Opportunity, Rec);
    end;

    procedure CloseOppFromOpp(var Opportunity: Record Opportunity)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCloseOppFromOpp(Opportunity, Rec, IsHandled);
        if IsHandled then
            exit;

        Opportunity.TestField(Closed, false);
        DeleteAll();
        Init();
        Validate("Opportunity No.", Opportunity."No.");
        "Sales Cycle Code" := Opportunity."Sales Cycle Code";
        "Contact No." := Opportunity."Contact No.";
        "Contact Company No." := Opportunity."Contact Company No.";
        "Salesperson Code" := Opportunity."Salesperson Code";
        "Campaign No." := Opportunity."Campaign No.";

        IsHandled := false;
        OnCloseOppFromOppOnBeforeStartWizard(Opportunity, Rec, IsHandled);
        if not IsHandled then
            StartWizard(Page::"Close Opportunity");
    end;

    local procedure StartWizard(PageID: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStartWizard(Rec, PageID, IsHandled);
        if IsHandled then
            exit;

        Insert();
        if Page.RunModal(PageID, Rec) = Action::OK then;
    end;

    procedure CheckStatus()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckStatus(Rec, IsHandled);
        if IsHandled then
            exit;

        if not ("Action Taken" in ["Action Taken"::Won, "Action Taken"::Lost]) then
            Error(Text011);
        if "Close Opportunity Code" = '' then
            ErrorMessage(FieldCaption("Close Opportunity Code"));
        if "Date of Change" = 0D then
            ErrorMessage(FieldCaption("Date of Change"));
        if "Action Taken" = "Action Taken"::Won then
            if "Calcd. Current Value (LCY)" <= 0 then
                Error(Text012);
    end;

    procedure FinishWizard()
    var
        OpportunityEntryToInsert: Record "Opportunity Entry";
    begin
        UpdateEstimates();
        OpportunityEntryToInsert := Rec;
        OnFinishWizardOnAfterUpdateEstimates(OpportunityEntryToInsert);
        InsertEntry(OpportunityEntryToInsert, "Cancel Old To Do", false);
        OnFinishWizardOnAfterInsertEntry(OpportunityEntryToInsert);
        Delete();
    end;

    local procedure ErrorMessage(FieldName: Text)
    begin
        Error(Text013, FieldName);
    end;

    procedure UpdateOppFromOpp(var Opportunity: Record Opportunity)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOppFromOpp(Opportunity, Rec, IsHandled);
        if IsHandled then
            exit;

        Opportunity.TestField(Closed, false);
        DeleteAll();
        Init();
        Validate("Opportunity No.", Opportunity."No.");
        "Sales Cycle Code" := Opportunity."Sales Cycle Code";
        "Contact No." := Opportunity."Contact No.";
        "Contact Company No." := Opportunity."Contact Company No.";
        "Salesperson Code" := Opportunity."Salesperson Code";
        "Campaign No." := Opportunity."Campaign No.";

        OnUpdateOppFromOppOnBeforeStartWizard2(Opportunity, Rec);
        StartWizard2();
    end;

    local procedure StartWizard2()
    var
        IsHandled: Boolean;
    begin
        "Wizard Step" := "Wizard Step"::"1";
        CreateStageList();
        Insert();

        IsHandled := false;
        OnStartWizard2OnBeforeRunModalPage(Rec, xRec, IsHandled);
        if not IsHandled then
            if Page.RunModal(Page::"Update Opportunity", Rec) = Action::OK then;
    end;

    procedure CheckStatus2()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckStatus2(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Action Type" = "Action Type"::" " then
            Error(Text006, "Sales Cycle Code");

        if EntryExists then
            if "Date of Change" < PreviousDateOfChange then
                Error(Text007);
        if "Date of Change" = 0D then
            ErrorMessage(FieldCaption("Date of Change"));

        ValidateStage();
        CheckEstimatedValues();
    end;

    procedure FinishWizard2()
    var
        CreateNewTask: Boolean;
        CancelOldTask: Boolean;
        IsHandled: Boolean;
    begin
        CancelOldTask := "Cancel Old To Do";
        CreateNewTask := "Action Taken" <> "Action Taken"::Updated;
        "Wizard Step" := "Wizard Step"::" ";
        "Cancel Old To Do" := false;
        UpdateEstimates();
        "Action Type" := "Action Type"::" ";
        IsHandled := false;
        OnFinishWizard2OnBeforeValidateSalesCycleStageDescription(OpportunityEntry, IsHandled);
        if not IsHandled then
            "Sales Cycle Stage Description" := '';
        OpportunityEntry := Rec;
        InsertEntry(OpportunityEntry, CancelOldTask, CreateNewTask);
        OnFinishWizard2OnAfterInsertEntry(OpportunityEntry);
        Delete();
    end;

    procedure WizardActionTypeValidate2()
    var
        ToDoTask: Record "To-do";
    begin
        case "Action Type" of
            "Action Type"::First:
                begin
                    TempSalesCycleStageFirst.FindFirst();
                    "Sales Cycle Stage" := TempSalesCycleStageFirst.Stage;
                    "Sales Cycle Stage Description" := TempSalesCycleStageFirst.Description;
                    "Action Taken" := "Action Taken"::" ";
                    "Cancel Old To Do" := false;
                end;
            "Action Type"::Next:
                begin
                    TempSalesCycleStageNext.FindFirst();
                    "Sales Cycle Stage" := TempSalesCycleStageNext.Stage;
                    "Sales Cycle Stage Description" := TempSalesCycleStageNext.Description;
                    "Action Taken" := "Action Taken"::Next;
                end;
            "Action Type"::Previous:
                begin
                    TempSalesCycleStagePrevious.FindFirst();
                    "Sales Cycle Stage" := TempSalesCycleStagePrevious.Stage;
                    "Sales Cycle Stage Description" := TempSalesCycleStagePrevious.Description;
                    "Action Taken" := "Action Taken"::Previous;
                end;
            "Action Type"::Skip:
                begin
                    TempSalesCycleStageSkip.FindFirst();
                    "Sales Cycle Stage" := TempSalesCycleStageSkip.Stage;
                    "Sales Cycle Stage Description" := TempSalesCycleStageSkip.Description;
                    "Action Taken" := "Action Taken"::Jumped;
                end;
            "Action Type"::Update:
                begin
                    TempSalesCycleStageUpdate.FindFirst();
                    "Sales Cycle Stage" := TempSalesCycleStageUpdate.Stage;
                    "Sales Cycle Stage Description" := TempSalesCycleStageUpdate.Description;
                    "Action Taken" := "Action Taken"::Updated;
                    "Cancel Old To Do" := false;
                end;
            "Action Type"::Jump:
                begin
                    TempSalesCycleStageJump.FindLast();
                    "Sales Cycle Stage" := TempSalesCycleStageJump.Stage;
                    "Sales Cycle Stage Description" := TempSalesCycleStageJump.Description;
                    "Action Taken" := "Action Taken"::Jumped;
                end;
        end;

        ToDoTask.SetCurrentKey("Opportunity No.");
        ToDoTask.SetRange("Opportunity No.", "Opportunity No.");
        if not ToDoTask.IsEmpty() then
            "Cancel Old To Do" := false;
        Modify();
    end;

    procedure WizardSalesCycleStageValidate2()
    begin
        case "Action Type" of
            "Action Type"::Skip:
                begin
                    if TempSalesCycleStageNext.Get("Sales Cycle Code", "Sales Cycle Stage") then
                        "Action Taken" := "Action Taken"::Next;
                    Modify();
                end;
            "Action Type"::Jump:
                begin
                    if TempSalesCycleStagePrevious.Get("Sales Cycle Code", "Sales Cycle Stage") then
                        "Action Taken" := "Action Taken"::Previous;
                    Modify();
                end;
        end;
        ValidateStage();
    end;

    procedure CreateStageList()
    var
        Stop: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateStageList(OpportunityEntry, Rec, IsHandled);
        if IsHandled then
            exit;

        TempSalesCycleStageFirst.DeleteAll();
        TempSalesCycleStageNext.DeleteAll();
        TempSalesCycleStagePrevious.DeleteAll();
        TempSalesCycleStageSkip.DeleteAll();
        TempSalesCycleStageUpdate.DeleteAll();
        TempSalesCycleStageJump.DeleteAll();

        OpportunityEntry.Reset();
        OpportunityEntry.SetCurrentKey(Active, "Opportunity No.");
        OpportunityEntry.SetRange(Active, true);
        OpportunityEntry.SetRange("Opportunity No.", "Opportunity No.");
        SalesCycleStage.Reset();
        SalesCycleStage.SetRange("Sales Cycle Code", "Sales Cycle Code");

        if OpportunityEntry.Find('-') then begin
            PreviousDateOfChange := OpportunityEntry."Date of Change";
            EntryExists := true;
        end else begin
            PreviousDateOfChange := WorkDate();
            EntryExists := false;
        end;

        // Option 1 Activate first Stage
        if not OpportunityEntry.Find('-') then
            if SalesCycleStage.Find('-') then begin
                TempSalesCycleStageFirst := SalesCycleStage;
                TempSalesCycleStageFirst.Insert();
            end;

        // Option 2 Goto next Stage
        if OpportunityEntry.Find('-') then
            if SalesCycleStage.Find('-') then begin
                SalesCycleStage.Get(OpportunityEntry."Sales Cycle Code", OpportunityEntry."Sales Cycle Stage");
                if SalesCycleStage.Find('>') then begin
                    TempSalesCycleStageNext := SalesCycleStage;
                    TempSalesCycleStageNext.Insert();
                end;
                "Sales Cycle Stage" := SalesCycleStage.Stage;
                "Action Taken" := "Action Taken"::Next;
            end;

        // Option 3 Goto Previous Stage
        if OpportunityEntry.Find('-') then
            if SalesCycleStage.Find('-') then begin
                SalesCycleStage.Get(OpportunityEntry."Sales Cycle Code", OpportunityEntry."Sales Cycle Stage");
                if SalesCycleStage.Find('<') then begin
                    TempSalesCycleStagePrevious := SalesCycleStage;
                    TempSalesCycleStagePrevious.Insert();
                end;
            end;

        // Option 4 Skip Stages
        if OpportunityEntry.Find('-') then
            if SalesCycleStage.Find('-') then begin
                SalesCycleStage.Get(OpportunityEntry."Sales Cycle Code", OpportunityEntry."Sales Cycle Stage");
                if SalesCycleStage.Find('>') then
                    if SalesCycleStage."Allow Skip" then begin
                        Stop := false;
                        repeat
                            TempSalesCycleStageSkip := SalesCycleStage;
                            TempSalesCycleStageSkip.Insert();
                            Stop := not SalesCycleStage."Allow Skip";
                        until (SalesCycleStage.Next() = 0) or Stop;
                    end;
            end else
                if SalesCycleStage.Find('-') then
                    if SalesCycleStage."Allow Skip" then begin
                        Stop := false;
                        repeat
                            TempSalesCycleStageSkip := SalesCycleStage;
                            TempSalesCycleStageSkip.Insert();
                            Stop := not SalesCycleStage."Allow Skip";
                        until (SalesCycleStage.Next() = 0) or Stop;
                    end;

        // Option 5 Update Current
        if OpportunityEntry.Find('-') then
            if SalesCycleStage.Find('-') then begin
                SalesCycleStage.Get(OpportunityEntry."Sales Cycle Code", OpportunityEntry."Sales Cycle Stage");
                TempSalesCycleStageUpdate := SalesCycleStage;
                TempSalesCycleStageUpdate.Insert();
            end;

        // Option 6 jump to Previous Stage
        if OpportunityEntry.Find('-') then
            if SalesCycleStage.Find('-') then begin
                Stop := false;
                repeat
                    TempSalesCycleStageJump := SalesCycleStage;
                    if TempSalesCycleStageJump.Stage <> OpportunityEntry."Sales Cycle Stage" then
                        TempSalesCycleStageJump.Insert()
                    else
                        Stop := true;
                until (SalesCycleStage.Next() = 0) or Stop;
            end;

        case true of
            NoOfSalesCyclesFirst() > 0:
                "Action Type" := "Action Type"::First;
            NoOfSalesCyclesNext() > 0:
                "Action Type" := "Action Type"::Next;
            NoOfSalesCyclesUpdate() > 0:
                "Action Type" := "Action Type"::Update;
            NoOfSalesCyclesPrev() > 0:
                "Action Type" := "Action Type"::Previous;
            NoOfSalesCyclesSkip() > 1:
                "Action Type" := "Action Type"::Skip;
            NoOfSalesCyclesJump() > 1:
                "Action Type" := "Action Type"::Jump;
        end;
    end;

    local procedure TestQuote()
    var
        Opportunity: Record Opportunity;
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestQuote(Rec, IsHandled);
        if IsHandled then
            exit;

        Opportunity.Get("Opportunity No.");
        if not SalesHeader.Get(SalesHeader."Document Type"::Quote, Opportunity."Sales Document No.") then
            Error(Text005);
    end;

    procedure ValidateStage()
    begin
        case "Action Type" of
            "Action Type"::First:
                TempSalesCycleStageFirst.Get("Sales Cycle Code", "Sales Cycle Stage");
            "Action Type"::Next:
                begin
                    ;
                    TempSalesCycleStageNext.Get("Sales Cycle Code", "Sales Cycle Stage");
                    if TempSalesCycleStageNext."Quote Required" then
                        TestQuote();
                end;
            "Action Type"::Previous:
                TempSalesCycleStagePrevious.Get("Sales Cycle Code", "Sales Cycle Stage");
            "Action Type"::Skip:
                begin
                    TempSalesCycleStageSkip.Get("Sales Cycle Code", "Sales Cycle Stage");
                    if TempSalesCycleStageSkip."Quote Required" then
                        TestQuote();
                end;
            "Action Type"::Update:
                TempSalesCycleStageUpdate.Get("Sales Cycle Code", "Sales Cycle Stage");
            "Action Type"::Jump:
                TempSalesCycleStageJump.Get("Sales Cycle Code", "Sales Cycle Stage");
        end;
        OnAfterValidateStage(Rec);
    end;

    procedure NoOfSalesCyclesFirst(): Integer
    begin
        exit(TempSalesCycleStageFirst.Count);
    end;

    procedure NoOfSalesCyclesNext(): Integer
    begin
        exit(TempSalesCycleStageNext.Count);
    end;

    procedure NoOfSalesCyclesPrev(): Integer
    begin
        exit(TempSalesCycleStagePrevious.Count);
    end;

    procedure NoOfSalesCyclesSkip(): Integer
    begin
        exit(TempSalesCycleStageSkip.Count);
    end;

    procedure NoOfSalesCyclesUpdate(): Integer
    begin
        exit(TempSalesCycleStageUpdate.Count);
    end;

    procedure NoOfSalesCyclesJump(): Integer
    begin
        exit(TempSalesCycleStageJump.Count);
    end;

    procedure ValidateSalesCycleStage()
    begin
        OnBeforeValidateSalesCycleStage(Rec);
        case "Action Type" of
            "Action Type"::First:
                TempSalesCycleStageFirst.Get("Sales Cycle Code", "Sales Cycle Stage");
            "Action Type"::Next:
                begin
                    ;
                    TempSalesCycleStageNext.Get("Sales Cycle Code", "Sales Cycle Stage");
                    if TempSalesCycleStageNext."Quote Required" then
                        TestQuote();
                end;
            "Action Type"::Previous:
                TempSalesCycleStagePrevious.Get("Sales Cycle Code", "Sales Cycle Stage");
            "Action Type"::Skip:
                begin
                    TempSalesCycleStageSkip.Get("Sales Cycle Code", "Sales Cycle Stage");
                    if TempSalesCycleStageSkip."Quote Required" then
                        TestQuote();
                end;
            "Action Type"::Update:
                TempSalesCycleStageUpdate.Get("Sales Cycle Code", "Sales Cycle Stage");
            "Action Type"::Jump:
                TempSalesCycleStageJump.Get("Sales Cycle Code", "Sales Cycle Stage");
        end;

        if SalesCycleStage.Get("Sales Cycle Code", "Sales Cycle Stage") then
            "Sales Cycle Stage Description" := SalesCycleStage.Description;
    end;

    procedure LookupSalesCycleStage()
    begin
        case "Action Type" of
            "Action Type"::First:
                if Action::LookupOK = Page.RunModal(0, TempSalesCycleStageFirst) then
                    "Sales Cycle Stage" := TempSalesCycleStageFirst.Stage;
            "Action Type"::Next:
                if Action::LookupOK = Page.RunModal(0, TempSalesCycleStageNext) then
                    "Sales Cycle Stage" := TempSalesCycleStageNext.Stage;
            "Action Type"::Previous:
                if Action::LookupOK = Page.RunModal(0, TempSalesCycleStagePrevious) then
                    "Sales Cycle Stage" := TempSalesCycleStagePrevious.Stage;
            "Action Type"::Skip:
                if Action::LookupOK = Page.RunModal(0, TempSalesCycleStageSkip) then
                    "Sales Cycle Stage" := TempSalesCycleStageSkip.Stage;
            "Action Type"::Update:
                if Action::LookupOK = Page.RunModal(0, TempSalesCycleStageUpdate) then
                    "Sales Cycle Stage" := TempSalesCycleStageUpdate.Stage;
            "Action Type"::Jump:
                if Action::LookupOK = Page.RunModal(0, TempSalesCycleStageJump) then
                    "Sales Cycle Stage" := TempSalesCycleStageJump.Stage;
        end;
        Validate("Sales Cycle Stage");
    end;

    local procedure CheckEstimatedValues()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEstimatedValues(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if "Estimated Value (LCY)" <= 0 then
            Error(Text008, FieldCaption("Estimated Value (LCY)"));
        if "Chances of Success %" <= 0 then
            Error(Text008, FieldCaption("Chances of Success %"));
        if "Estimated Close Date" = 0D then
            ErrorMessage(FieldCaption("Estimated Close Date"));
        if "Estimated Close Date" < "Date of Change" then
            Error(Text009);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOpportunityEntry(Opportunity: Record Opportunity; var OpportunityEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertEntry(var OpportunityEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateStage(var OpportunityEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckStatus(var OpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckStatus2(var OpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCloseOppFromOpp(var Opportunity: Record Opportunity; var OpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateStageList(var OpportunityEntry: Record "Opportunity Entry"; var OpportunityEntryRec: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesDocValue(SalesHeader: Record "Sales Header"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartWizard(var OpportunityEntry: Record "Opportunity Entry"; var CloseOpportunityPageId: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestCust(OpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateEstimates(var OpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOppFromOpp(var Opportunity: Record Opportunity; var OpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSalesCycleStage(var OpportunityEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCloseOppFromOppOnBeforeStartWizard(Opportunity: Record Opportunity; var OpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTaskOnBeforeInsertTask(var OpportunityEntry: Record "Opportunity Entry"; var Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishWizardOnAfterInsertEntry(OpportunityEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishWizard2OnAfterInsertEntry(OpportunityEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEstimatesOnBeforeModifyOpportunityEntry(var OpportunityEntry: Record "Opportunity Entry"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOppFromOppOnBeforeStartWizard2(Opportunity: Record Opportunity; var OpportunityEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestQuote(OpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckEstimatedValues(var OpportunityEntry: Record "Opportunity Entry"; xOpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnStartWizard2OnBeforeRunModalPage(var OpportunityEntry: Record "Opportunity Entry"; xOpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishWizard2OnBeforeValidateSalesCycleStageDescription(var OpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishWizardOnAfterUpdateEstimates(var OpportunityEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnInsertOnBeforeModifyOpportunity(var OpportunityEntry: Record "Opportunity Entry"; var Opportunity: Record Opportunity; var ShouldModifyOpportunity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertEntryOnBeforeInsert(var OpportunityEntryToInsert: Record "Opportunity Entry"; var OpportunityEntryInserted: Record "Opportunity Entry")
    begin
    end;
}
