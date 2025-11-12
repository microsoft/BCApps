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
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.Foundation.NoSeries;
using Microsoft.Integration.Dataverse;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Security.User;
using System.Utilities;

table 5092 Opportunity
{
    Caption = 'Opportunity';
    DataCaptionFields = "No.", Description;
    DataClassification = CustomerContent;
    DrillDownPageID = "Opportunity List";
    LookupPageID = "Opportunity List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    RMSetup.Get();
                    NoSeries.TestManual(RMSetup."Opportunity Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            var
                Task: Record "To-do";
                Task2: Record "To-do";
                OppEntry: Record "Opportunity Entry";
                Attendee: Record Attendee;
                Window: Dialog;
                TotalRecordsNumber: Integer;
                Counter: Integer;
            begin
                if ("Salesperson Code" <> xRec."Salesperson Code") and
                   (xRec."Salesperson Code" <> '') and
                   ("No." <> '')
                then begin
                    TestField("Salesperson Code");
                    Task.Reset();
                    Task.SetCurrentKey("Opportunity No.", Date, Closed);
                    Task.SetRange("Opportunity No.", "No.");
                    Task.SetRange(Closed, false);
                    Task.SetRange("Salesperson Code", xRec."Salesperson Code");
                    TotalRecordsNumber := Task.Count();
                    Counter := 0;
                    if Task.Find('-') then
                        if Confirm(ChangeConfirmQst, false, FieldCaption("Salesperson Code")) then begin
                            Window.Open(Text012 + Text013);
                            Window.Update(2, Text014);
                            repeat
                                Counter := Counter + 1;
                                Window.Update(1, Round(Counter / TotalRecordsNumber * 10000, 1));
                                if Task.Type = Task.Type::Meeting then begin
                                    Task.GetMeetingOrganizerTask(Task2);
                                    if Task."Salesperson Code" <> Task2."Salesperson Code" then begin
                                        Task.Validate("Salesperson Code", "Salesperson Code");
                                        Task.Modify();
                                    end;
                                    Attendee.Reset();
                                    Attendee.SetRange("To-do No.", Task2."No.");
                                    Attendee.SetRange("Attendee No.", xRec."Salesperson Code");
                                    Attendee.SetRange("Attendee Type", Attendee."Attendee Type"::Salesperson);
                                    Attendee.SetRange("Attendance Type", Attendee."Attendance Type"::Required, Attendee."Attendance Type"::Optional);
                                    if Attendee.FindFirst() then begin
                                        Attendee.Validate("Attendee No.", "Salesperson Code");
                                        Attendee.Modify(true);
                                    end;
                                end
                                else begin
                                    Task.Validate("Salesperson Code", "Salesperson Code");
                                    Task.Modify(true);
                                end;
                            until Task.Next() = 0;
                            Window.Close();
                        end;

                    OppEntry.Reset();
                    OppEntry.SetCurrentKey(Active, "Opportunity No.");
                    OppEntry.SetRange(Active, true);
                    OppEntry.SetRange("Opportunity No.", "No.");
                    if OppEntry.Find('-') then
                        repeat
                            OppEntry."Salesperson Code" := "Salesperson Code";
                            OppEntry.Modify();
                        until OppEntry.Next() = 0;

                    Modify();
                end;
            end;
        }
        field(4; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnLookup()
            begin
                LookupCampaigns();
            end;

            trigger OnValidate()
            var
                Task: Record "To-do";
                OppEntry: Record "Opportunity Entry";
            begin
                if ("Campaign No." <> xRec."Campaign No.") and
                   ("No." <> '')
                then begin
                    CheckCampaign();
                    SetDefaultSegmentNo();
                    Task.Reset();
                    Task.SetCurrentKey("Opportunity No.", Date, Closed);
                    Task.SetRange("Opportunity No.", "No.");
                    Task.SetRange(Closed, false);
                    Task.SetRange("Campaign No.", xRec."Campaign No.");
                    if Task.Find('-') then
                        if Confirm(ChangeConfirmQst, false, FieldCaption("Campaign No.")) then
                            repeat
                                Task."Campaign No." := "Campaign No.";
                                Task.Modify();
                            until Task.Next() = 0;

                    OppEntry.Reset();
                    OppEntry.SetCurrentKey(Active, "Opportunity No.");
                    OppEntry.SetRange(Active, true);
                    OppEntry.SetRange("Opportunity No.", "No.");
                    if OppEntry.Find('-') then
                        repeat
                            OppEntry."Campaign No." := "Campaign No.";
                            OppEntry.Modify();
                        until OppEntry.Next() = 0;

                    Modify();
                end;
            end;
        }
        field(5; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
            begin
                if Cont.Get("Contact No.") and (Status <> Status::"Not Started") then
                    Cont.SetRange("Company No.", Cont."Company No.");
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec."Contact No." := "Contact No.";
                    Validate("Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                Task: Record "To-do";
                Task2: Record "To-do";
                OppEntry: Record "Opportunity Entry";
                SalesHeader: Record "Sales Header";
                Attendee: Record Attendee;
                Window: Dialog;
                TotalRecordsNumber: Integer;
                Counter: Integer;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateContactNo(Rec, CurrFieldNo, IsHandled, xRec);
                if IsHandled then
                    exit;

                TestField("Contact No.");
                Cont.Get("Contact No.");

                if ("Contact No." <> xRec."Contact No.") and
                   (xRec."Contact No." <> '') and
                   ("No." <> '')
                then begin
                    CalcFields("Contact Name");
                    if ("Contact Company No." <> Cont."Company No.") and
                       (Status <> Status::"Not Started")
                    then
                        Error(Text009, Cont."No.", Cont.Name);

                    if ("Sales Document No." <> '') and ("Sales Document Type" = "Sales Document Type"::Quote) then begin
                        SalesHeader.Get(SalesHeader."Document Type"::Quote, "Sales Document No.");
                        if SalesHeader."Sell-to Contact No." <> "Contact No." then begin
                            Modify();
                            SalesHeader.SetHideValidationDialog(true);
                            SalesHeader.Validate("Sell-to Contact No.", "Contact No.");
                            SalesHeader.Modify();
                        end
                    end;
                    Task.Reset();
                    Task.SetCurrentKey("Opportunity No.", Date, Closed);
                    Task.SetRange("Opportunity No.", "No.");
                    Task.SetRange(Closed, false);
                    Task.SetRange("Contact No.", xRec."Contact No.");
                    TotalRecordsNumber := Task.Count();
                    Counter := 0;
                    if Task.Find('-') then
                        if Confirm(ChangeConfirmQst, false, FieldCaption("Contact No.")) then begin
                            Window.Open(Text012 + Text013);
                            Window.Update(2, Text014);
                            repeat
                                Counter := Counter + 1;
                                Window.Update(1, Round(Counter / TotalRecordsNumber * 10000, 1));
                                if Task.Type = Task.Type::Meeting then begin
                                    Task.GetMeetingOrganizerTask(Task2);
                                    Task.Validate("Contact No.", "Contact No.");
                                    Task.Modify();
                                    Attendee.Reset();
                                    Attendee.SetRange("To-do No.", Task2."No.");
                                    Attendee.SetRange("Attendee No.", xRec."Contact No.");
                                    Attendee.SetRange("Attendee Type", Attendee."Attendee Type"::Contact);
                                    if Attendee.FindFirst() then begin
                                        Attendee.Validate("Attendee No.", "Contact No.");
                                        Attendee.Modify(true);
                                    end;
                                end else begin
                                    Task.Validate("Contact No.", "Contact No.");
                                    Task.Modify(true);
                                end;
                            until Task.Next() = 0;
                            Window.Close();
                        end;

                    OppEntry.Reset();
                    OppEntry.SetCurrentKey(Active, "Opportunity No.");
                    OppEntry.SetRange(Active, true);
                    OppEntry.SetRange("Opportunity No.", "No.");
                    if OppEntry.Find('-') then
                        repeat
                            OppEntry.Validate("Contact No.", "Contact No.");
                            OppEntry.Modify();
                        until OppEntry.Next() = 0;

                    Modify();
                end;

                "Contact Company No." := Cont."Company No.";
                CalcFields("Contact Name", "Contact Company Name");
            end;
        }
        field(6; "Contact Company No."; Code[20])
        {
            Caption = 'Contact Company No.';
            TableRelation = Contact where(Type = const(Company));
        }
        field(7; "Sales Cycle Code"; Code[10])
        {
            Caption = 'Sales Cycle Code';
            TableRelation = "Sales Cycle";

            trigger OnValidate()
            var
                SalesCycle: Record "Sales Cycle";
            begin
                SalesCycle.Get("Sales Cycle Code");
                SalesCycle.TestField(Blocked, false);
            end;
        }
        field(8; "Sales Document No."; Code[20])
        {
            Caption = 'Sales Document No.';
            TableRelation = if ("Sales Document Type" = const(Quote)) "Sales Header"."No." where("Document Type" = const(Quote),
                                                                                                "Sell-to Contact No." = field("Contact No."))
            else
            if ("Sales Document Type" = const(Order)) "Sales Header"."No." where("Document Type" = const(Order),
                                                                                                                                                                         "Sell-to Contact No." = field("Contact No."))
            else
            if ("Sales Document Type" = const("Posted Invoice")) "Sales Invoice Header"."No." where("Sell-to Contact No." = field("Contact No."));

            trigger OnValidate()
            var
                Opp: Record Opportunity;
                SalesHeader: Record "Sales Header";
            begin
                if "Sales Document No." = '' then begin
                    "Sales Document Type" := "Sales Document Type"::" ";
                    if xRec."Sales Document Type" = "Sales Document Type"::Quote then
                        if SalesHeader.Get(SalesHeader."Document Type"::Quote, xRec."Sales Document No.") then begin
                            SalesHeader."Opportunity No." := '';
                            SalesHeader.Modify();
                        end
                end else
                    if "Sales Document No." <> xRec."Sales Document No." then begin
                        Opp.Reset();
                        Opp.SetCurrentKey("Sales Document Type", "Sales Document No.");
                        Opp.SetRange("Sales Document Type", "Sales Document Type");
                        Opp.SetRange("Sales Document No.", "Sales Document No.");
                        if Opp.FindFirst() then
                            if Opp."No." <> "No." then
                                Error(Text006, Opp."Sales Document Type", Opp."Sales Document No.", Opp."No.");

                        if xRec."Sales Document Type" = "Sales Document Type"::Quote then
                            if SalesHeader.Get(SalesHeader."Document Type"::Quote, xRec."Sales Document No.") then begin
                                SalesHeader."Opportunity No." := '';
                                SalesHeader.Modify();
                            end;
                        if "Sales Document Type" = "Sales Document Type"::Quote then
                            if SalesHeader.Get(SalesHeader."Document Type"::Quote, "Sales Document No.") then begin
                                SalesHeader."Opportunity No." := "No.";
                                SalesHeader.Modify();
                            end
                    end;
            end;
        }
        field(9; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(10; Status; Enum "Opportunity Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(11; Priority; Enum "Opportunity Priority")
        {
            Caption = 'Priority';
            InitValue = Normal;
        }
        field(12; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
        field(13; "Date Closed"; Date)
        {
            Caption = 'Date Closed';
            Editable = false;
        }
        field(15; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(16; Comment; Boolean)
        {
            CalcFormula = exist("Rlshp. Mgt. Comment Line" where("Table Name" = const(Opportunity),
                                                                  "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Current Sales Cycle Stage"; Integer)
        {
            BlankZero = true;
            CalcFormula = lookup("Opportunity Entry"."Sales Cycle Stage" where("Opportunity No." = field("No."),
                                                                                Active = const(true)));
            Caption = 'Current Sales Cycle Stage';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Estimated Value (LCY)" where("Opportunity No." = field("No."),
                                                                                 Active = const(true)));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Probability %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = lookup("Opportunity Entry"."Probability %" where("Opportunity No." = field("No."),
                                                                            Active = const(true)));
            Caption = 'Probability %';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Calcd. Current Value (LCY)" where("Opportunity No." = field("No."),
                                                                                      Active = const(true)));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; "Chances of Success %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = lookup("Opportunity Entry"."Chances of Success %" where("Opportunity No." = field("No."),
                                                                                   Active = const(true)));
            Caption = 'Chances of Success %';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "Completed %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = lookup("Opportunity Entry"."Completed %" where("Opportunity No." = field("No."),
                                                                          Active = const(true)));
            Caption = 'Completed %';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Contact Company Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact Company No.")));
            Caption = 'Contact Company Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "Salesperson Name"; Text[50])
        {
            CalcFormula = lookup("Salesperson/Purchaser".Name where(Code = field("Salesperson Code")));
            Caption = 'Salesperson Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Campaign Description"; Text[100])
        {
            CalcFormula = lookup(Campaign.Description where("No." = field("Campaign No.")));
            Caption = 'Campaign Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
            TableRelation = "Segment Header";

            trigger OnLookup()
            begin
                LookupSegments();
            end;

            trigger OnValidate()
            var
                SegmentHeader: Record "Segment Header";
            begin
                if ("Segment No." <> xRec."Segment No.") and ("Segment No." <> '') and ("Campaign No." <> '') then
                    CheckSegmentCampaignNo();
                if "Segment No." <> '' then
                    SegmentHeader.Get("Segment No.");
                Validate("Segment Description", SegmentHeader.Description);
            end;
        }
        field(28; "Estimated Closing Date"; Date)
        {
            CalcFormula = lookup("Opportunity Entry"."Estimated Close Date" where("Opportunity No." = field("No."),
                                                                                   Active = const(true)));
            Caption = 'Estimated Closing Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Sales Document Type"; Enum "Opportunity Document Type")
        {
            Caption = 'Sales Document Type';

            trigger OnValidate()
            begin
                if "Sales Document Type" = xRec."Sales Document Type" then
                    exit;
                if "Sales Document Type" = "Sales Document Type"::" " then
                    Validate("Sales Document No.", '');
            end;
        }
        field(30; "No. of Interactions"; Integer)
        {
            CalcFormula = count("Interaction Log Entry" where("Opportunity No." = field(filter("No.")),
                                                               Canceled = const(false),
                                                               Postponed = const(false)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::Opportunity)));
        }
        field(9501; "Wizard Step"; Option)
        {
            Caption = 'Wizard Step';
            Editable = false;
            OptionCaption = ' ,1,2,3,4,5,6';
            OptionMembers = " ","1","2","3","4","5","6";
        }
        field(9502; "Activate First Stage"; Boolean)
        {
            Caption = 'Activate First Stage';
        }
        field(9503; "Segment Description"; Text[100])
        {
            Caption = 'Segment Description';
        }
        field(9504; "Wizard Estimated Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Wizard Estimated Value (LCY)';
        }
        field(9505; "Wizard Chances of Success %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Wizard Chances of Success %';
            DecimalPlaces = 0 : 0;
        }
        field(9506; "Wizard Estimated Closing Date"; Date)
        {
            Caption = 'Wizard Estimated Closing Date';
        }
        field(9507; "Wizard Contact Name"; Text[100])
        {
            Caption = 'Wizard Contact Name';
        }
        field(9508; "Wizard Campaign Description"; Text[100])
        {
            Caption = 'Wizard Campaign Description';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Contact Company No.", "Contact No.", Closed)
        {
        }
        key(Key3; "Salesperson Code", Closed)
        {
        }
        key(Key4; "Campaign No.", Closed)
        {
        }
        key(Key5; "Segment No.", Closed)
        {
        }
        key(Key6; "Sales Document Type", "Sales Document No.")
        {
        }
        key(Key7; Description)
        {
        }
        key(Key8; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Creation Date", Status)
        {
        }
    }

    trigger OnDelete()
    var
        OppEntry: Record "Opportunity Entry";
    begin
        if Status = Status::"In Progress" then
            Error(Text000);

        RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::Opportunity);
        RMCommentLine.SetRange("No.", "No.");
        RMCommentLine.DeleteAll();

        OppEntry.SetCurrentKey("Opportunity No.");
        OppEntry.SetRange("Opportunity No.", "No.");
        OppEntry.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            RMSetup.Get();
            RMSetup.TestField("Opportunity Nos.");
            if NoSeries.AreRelated(RMSetup."Opportunity Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := RMSetup."Opportunity Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;

        if "Salesperson Code" = '' then
            SetDefaultSalesperson();

        "Creation Date" := WorkDate();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'You cannot delete this opportunity while it is active.';
        Text001: Label 'You cannot create opportunities on an empty segment.';
#pragma warning disable AA0470
        Text002: Label 'Do you want to create an opportunity for all contacts in the %1 segment?';
#pragma warning restore AA0470
        Text003: Label 'There is no sales quote that is assigned to this opportunity.';
#pragma warning disable AA0470
        Text004: Label 'Sales quote %1 does not exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        RMSetup: Record "Marketing Setup";
        Opp: Record Opportunity;
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
        OppEntry: Record "Opportunity Entry";
        TempRlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line" temporary;
        NoSeries: Codeunit "No. Series";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'Sales %1 %2 is already assigned to opportunity %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ChangeConfirmQst: Label 'Do you want to change %1 on the related open tasks with the same %1?', Comment = '%1 = Field Caption';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text009: Label 'Contact %1 %2 is related to another company.';
#pragma warning restore AA0470
        Text011: Label 'A sales quote has already been assigned to this opportunity.';
        Text012: Label 'Current process @1@@@@@@@@@@@@@@@\';
#pragma warning disable AA0470
        Text013: Label 'Current status  #2###############';
#pragma warning restore AA0470
        Text014: Label 'Updating Tasks';
#pragma warning disable AA0470
        Text022: Label 'You must fill in the %1 field.';
#pragma warning restore AA0470
        Text023: Label 'You must fill in the contact that is involved in the opportunity.';
#pragma warning disable AA0470
        Text024: Label '%1 must be greater than 0.';
#pragma warning restore AA0470
        Text025: Label 'The Estimated closing date has to be later than this change';
#pragma warning restore AA0074
        ActivateFirstStageQst: Label 'Would you like to activate first stage for this opportunity?';
        SalesCycleNotFoundErr: Label 'Sales Cycle Stage not found.';
        UpdateSalesQuoteWithCustTemplateQst: Label 'Do you want to update the sales quote with a customer template?';

    procedure CreateFromInteractionLogEntry(InteractionLogEntry: Record "Interaction Log Entry")
    begin
        Init();
        "No." := '';
        "Creation Date" := WorkDate();
        Description := InteractionLogEntry.Description;
        "Segment No." := InteractionLogEntry."Segment No.";
        "Segment Description" := InteractionLogEntry.Description;
        "Campaign No." := InteractionLogEntry."Campaign No.";
        "Salesperson Code" := InteractionLogEntry."Salesperson Code";
        "Contact No." := InteractionLogEntry."Contact No.";
        "Contact Company No." := InteractionLogEntry."Contact Company No.";
        SetDefaultSalesCycle();
        OnCreateFromCreateFromInteractionLogEntryOnBeforeInsert(Rec, InteractionLogEntry);
        Insert(true);
        CopyCommentLinesFromIntLogEntry(InteractionLogEntry);
    end;

    procedure CreateFromSegmentLine(SegmentLine: Record "Segment Line")
    begin
        Init();
        "No." := '';
        "Creation Date" := WorkDate();
        Description := SegmentLine.Description;
        "Segment No." := SegmentLine."Segment No.";
        "Segment Description" := SegmentLine.Description;
        "Campaign No." := SegmentLine."Campaign No.";
        "Salesperson Code" := SegmentLine."Salesperson Code";
        "Contact No." := SegmentLine."Contact No.";
        "Contact Company No." := SegmentLine."Contact Company No.";
        SetDefaultSalesCycle();
        OnCreateFromSegmentLineOnBeforeInsert(Rec, SegmentLine);
        Insert(true);
    end;

    procedure CreateOppFromOpp(var Opportunity: Record Opportunity)
    var
        Contact: Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        IsHandled: Boolean;
        DoSetDefaultSalesCycle: Boolean;
    begin
        DeleteAll();
        Init();
        DoSetDefaultSalesCycle := true;
        OnCreateOppFromOppOnAfterInit(Opportunity, DoSetDefaultSalesCycle);
        "Creation Date" := WorkDate();
        if DoSetDefaultSalesCycle then
            SetDefaultSalesCycle();
        if Contact.Get(Opportunity.GetFilter("Contact Company No.")) then begin
            Validate("Contact No.", Contact."No.");
            "Salesperson Code" := Contact."Salesperson Code";
            SetRange("Contact Company No.", "Contact No.");
        end;
        if Contact.Get(Opportunity.GetFilter("Contact No.")) then begin
            Validate("Contact No.", Contact."No.");
            "Salesperson Code" := Contact."Salesperson Code";
            SetRange("Contact No.", "Contact No.");
        end;
        IsHandled := false;
        OnCreateOppFromOppOnBeforeSetFilterSalesPersonCode(Rec, IsHandled, Opportunity);
        if not IsHandled then
            if SalespersonPurchaser.Get(Opportunity.GetFilter("Salesperson Code")) then begin
                "Salesperson Code" := SalespersonPurchaser.Code;
                SetRange("Salesperson Code", "Salesperson Code");
            end;
        if Campaign.Get(Opportunity.GetFilter("Campaign No.")) then begin
            "Campaign No." := Campaign."No.";
            "Salesperson Code" := Campaign."Salesperson Code";
            SetRange("Campaign No.", "Campaign No.");
        end;
        if SegmentHeader.Get(Opportunity.GetFilter("Segment No.")) then begin
            SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
            if SegmentLine.Count = 0 then
                Error(Text001);
            "Segment No." := SegmentHeader."No.";
            "Campaign No." := SegmentHeader."Campaign No.";
            "Salesperson Code" := SegmentHeader."Salesperson Code";
            SetRange("Segment No.", "Segment No.");
        end;

        StartWizard();
    end;

    local procedure InsertOpportunity(var Opp2: Record Opportunity; OppEntry2: Record "Opportunity Entry"; var TempRlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line"; ActivateFirstStage: Boolean)
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        Opp := Opp2;

        if ActivateFirstStage then begin
            SalesCycleStage.Reset();
            SalesCycleStage.SetRange("Sales Cycle Code", Opp."Sales Cycle Code");
            if SalesCycleStage.FindFirst() then
                OppEntry2."Sales Cycle Stage" := SalesCycleStage.Stage;
        end;

        if SegmentHeader.Get(GetFilter("Segment No.")) then begin
            SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
            SegmentLine.SetFilter("Contact No.", '<>%1', '');
            if SegmentLine.Find('-') then
                if Confirm(Text002, true, SegmentHeader."No.") then
                    repeat
                        Opp."Contact No." := SegmentLine."Contact No.";
                        Opp."Contact Company No." := SegmentLine."Contact Company No.";
                        Clear(Opp."No.");
                        Opp.Insert(true);
                        CreateCommentLines(TempRlshpMgtCommentLine, Opp."No.");
                        ProcessFirstStage(OppEntry2, ActivateFirstStage, true, SegmentLine."Salesperson Code");
                    until SegmentLine.Next() = 0;
        end else begin
            Opp.Insert(true);
            CreateCommentLines(TempRlshpMgtCommentLine, Opp."No.");
            ProcessFirstStage(OppEntry2, ActivateFirstStage, false, '');
        end;

        OnAfterInsertOpportunity(Opp);
    end;

    local procedure ProcessFirstStage(OpportunityEntry2: Record "Opportunity Entry"; ActivateFirstStage: Boolean; CalledForSegment: Boolean; SalesPersonCode: Code[20])
    var
        OpportunityEntry: Record "Opportunity Entry";
    begin
        OnBeforeProcessFirstStage(Opp, OpportunityEntry2, ActivateFirstStage, CalledForSegment, SalesPersonCode);

        if ActivateFirstStage then begin
            OpportunityEntry.Init();
            OpportunityEntry := OpportunityEntry2;
            OpportunityEntry.InitOpportunityEntry(Opp);
            OpportunityEntry.InsertEntry(OpportunityEntry, false, true);
            OpportunityEntry.UpdateEstimates();
        end;

        OnAfterProcessFirstStage(OpportunityEntry);
    end;

    procedure UpdateOpportunity()
    var
        TempOppEntry: Record "Opportunity Entry" temporary;
    begin
        OnBeforeUpdateOpportunity(Rec);
        if "No." <> '' then
            TempOppEntry.UpdateOppFromOpp(Rec);
    end;

    procedure CloseOpportunity()
    var
        TempOppEntry: Record "Opportunity Entry" temporary;
    begin
        if "No." <> '' then
            TempOppEntry.CloseOppFromOpp(Rec);
    end;

    procedure CreateQuote()
    var
        Cont: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        SalesHeader: Record "Sales Header";
        NewCustTemplateCode: Code[20];
    begin
        Cont.Get("Contact No.");

        if SalesHeader.Get(SalesHeader."Document Type"::Quote, "Sales Document No.") then
            Error(Text011);

        if (Cont.Type = Cont.Type::Person) and (Cont."Company No." <> '') then
            Cont.Get(Cont."Company No.");

        if Cont.Type = Cont.Type::Company then begin
            ContactBusinessRelation.SetRange("Contact No.", Cont."No.");
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
            if ContactBusinessRelation.IsEmpty() then
                NewCustTemplateCode := GetNewCustomerTemplateCode(Cont);
        end;

        TestField(Status, Status::"In Progress");

        SalesHeader.SetRange("Sell-to Contact No.", "Contact No.");
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
        OnCreateQuoteOnBeforeSalesHeaderInsert(SalesHeader, Rec);
        SalesHeader.Insert(true);
        OnCreateQuoteOnAfterSalesHeaderInsert(SalesHeader, Rec);
        SalesHeader.Validate("Salesperson Code", "Salesperson Code");
        SalesHeader.Validate("Campaign No.", "Campaign No.");
        SalesHeader."Opportunity No." := "No.";
        SalesHeader."Order Date" := GetEstimatedClosingDate();
        SalesHeader."Shipment Date" := SalesHeader."Order Date";
        if NewCustTemplateCode <> '' then
            SalesHeader.Validate("Sell-to Customer Templ. Code", NewCustTemplateCode);
        SalesHeader.Modify();
        "Sales Document Type" := "Sales Document Type"::Quote;
        "Sales Document No." := SalesHeader."No.";
        Modify();

        OnCreateQuoteOnBeforePageRun(SalesHeader, Rec);
        RunQuotePage(SalesHeader, false);
    end;

    local procedure GetNewCustomerTemplateCode(Cont: Record Contact) CustTemplateCode: Code[20]
    var
        CustTemplate: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNewCustomerTemplateCode(Cont, CustTemplateCode, IsHandled);
        if IsHandled then
            exit(CustTemplateCode);

        if GuiAllowed then begin
            CustTemplateCode := Cont.ChooseNewCustomerTemplate();
            if CustTemplateCode <> '' then
                Cont.CreateCustomerFromTemplate(CustTemplateCode)
            else
                if Confirm(UpdateSalesQuoteWithCustTemplateQst) then
                    if CustomerTemplMgt.SelectCustomerTemplate(CustTemplate) then
                        CustTemplateCode := CustTemplate.Code;
        end;
    end;

    local procedure GetEstimatedClosingDate(): Date
    var
        OppEntry: Record "Opportunity Entry";
    begin
        OppEntry.SetCurrentKey(Active, "Opportunity No.");
        OppEntry.SetRange(Active, true);
        OppEntry.SetRange("Opportunity No.", "No.");
        if OppEntry.FindFirst() then
            exit(OppEntry."Estimated Close Date");
    end;

    procedure ShowQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        if SalesHeader.Get(SalesHeader."Document Type"::Quote, "Sales Document No.") then
            RunQuotePage(SalesHeader, true);
    end;

    local procedure CreateCommentLines(var TempRlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line"; OppNo: Code[20])
    begin
        if TempRlshpMgtCommentLine.Find('-') then
            repeat
                RMCommentLine.Init();
                RMCommentLine := TempRlshpMgtCommentLine;
                RMCommentLine."No." := OppNo;
                RMCommentLine.Insert();
            until TempRlshpMgtCommentLine.Next() = 0;
    end;

    local procedure CopyCommentLinesFromIntLogEntry(InteractionLogEntry: Record "Interaction Log Entry")
    var
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
    begin
        InterLogEntryCommentLine.SetRange("Entry No.", InteractionLogEntry."Entry No.");
        if InterLogEntryCommentLine.FindSet() then
            repeat
                RlshpMgtCommentLine.Init();
                RlshpMgtCommentLine."Table Name" := RlshpMgtCommentLine."Table Name"::Opportunity;
                RlshpMgtCommentLine."No." := "No.";
                RlshpMgtCommentLine."Line No." := InterLogEntryCommentLine."Line No.";
                RlshpMgtCommentLine.Date := InterLogEntryCommentLine.Date;
                RlshpMgtCommentLine.Code := InterLogEntryCommentLine.Code;
                RlshpMgtCommentLine.Comment := InterLogEntryCommentLine.Comment;
                RlshpMgtCommentLine."Last Date Modified" := InterLogEntryCommentLine."Last Date Modified";
                RlshpMgtCommentLine.Insert();
            until InterLogEntryCommentLine.Next() = 0;
    end;

    local procedure StartWizard()
    var
        Cont: Record Contact;
        Campaign: Record Campaign;
        SegHeader: Record "Segment Header";
    begin
        "Wizard Step" := "Wizard Step"::"1";

        if Cont.Get(GetFilter("Contact No.")) then
            "Wizard Contact Name" := Cont.Name
        else
            if Cont.Get(GetFilter("Contact Company No.")) then
                "Wizard Contact Name" := Cont.Name;

        if Campaign.Get(GetFilter("Campaign No.")) then
            "Wizard Campaign Description" := Campaign.Description;
        if SegHeader.Get(GetFilter("Segment No.")) then
            "Segment Description" := SegHeader.Description;

        OnStartWizardBeforeInsert(Rec);
        Insert();
        RunPageForRec(PAGE::"Create Opportunity");

    end;

    local procedure RunPageForRec(PageID: Integer)
    begin
        OnBeforeRunPageForRec(Rec, PageID);
        if PAGE.RunModal(PageID, Rec) = ACTION::OK then;
    end;

    procedure CheckStatus()
    var
        SegmentHeader: Record "Segment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckStatus(Rec, OppEntry, IsHandled);
        if IsHandled then
            exit;

        if "Creation Date" = 0D then
            ErrorMessage(FieldCaption("Creation Date"));
        if Description = '' then
            ErrorMessage(FieldCaption(Description));

        if not SegmentHeader.Get(GetFilter("Segment No.")) then
            if "Contact No." = '' then
                Error(Text023);
        if "Salesperson Code" = '' then
            ErrorMessage(FieldCaption("Salesperson Code"));
        if "Sales Cycle Code" = '' then
            ErrorMessage(FieldCaption("Sales Cycle Code"));

        if "Activate First Stage" then begin
            if "Wizard Estimated Value (LCY)" <= 0 then
                Error(Text024, FieldCaption("Wizard Estimated Value (LCY)"));
            if "Wizard Chances of Success %" <= 0 then
                Error(Text024, FieldCaption("Wizard Chances of Success %"));
            if "Wizard Estimated Closing Date" = 0D then
                ErrorMessage(FieldCaption("Wizard Estimated Closing Date"));
            if "Wizard Estimated Closing Date" < OppEntry."Date of Change" then
                Error(Text025);
        end;
    end;

    procedure FinishWizard()
    var
        ActivateFirstStage: Boolean;
    begin
        OnBeforeFinishWizard(Rec, OppEntry);
        "Wizard Step" := Opp."Wizard Step"::" ";
        ActivateFirstStage := "Activate First Stage";
        "Activate First Stage" := false;
        OppEntry."Chances of Success %" := "Wizard Chances of Success %";
        OppEntry."Estimated Close Date" := "Wizard Estimated Closing Date";
        OppEntry."Estimated Value (LCY)" := "Wizard Estimated Value (LCY)";

        "Wizard Chances of Success %" := 0;
        "Wizard Estimated Closing Date" := 0D;
        "Wizard Estimated Value (LCY)" := 0;
        "Segment Description" := '';
        "Wizard Contact Name" := '';
        "Wizard Campaign Description" := '';

        OnFinishWizardOnBeforeInsertOpportunity(Rec, OppEntry);
        InsertOpportunity(Rec, OppEntry, TempRlshpMgtCommentLine, ActivateFirstStage);
        Delete();

        OnAfterFinishWizard(Rec);
    end;

    local procedure ErrorMessage(FieldName: Text[1024])
    begin
        Error(Text022, FieldName);
    end;

    procedure SetComments(var RMCommentLine: Record "Rlshp. Mgt. Comment Line")
    begin
        TempRlshpMgtCommentLine.DeleteAll();

        if RMCommentLine.FindSet() then
            repeat
                TempRlshpMgtCommentLine := RMCommentLine;
                TempRlshpMgtCommentLine.Insert();
            until RMCommentLine.Next() = 0;
    end;

    procedure ShowSalesQuoteWithCheck()
    var
        SalesHeader: Record "Sales Header";
    begin
        if ("Sales Document Type" <> "Sales Document Type"::Quote) or
           ("Sales Document No." = '')
        then
            Error(Text003);

        if not SalesHeader.Get(SalesHeader."Document Type"::Quote, "Sales Document No.") then
            Error(Text004, "Sales Document No.");
        RunQuotePage(SalesHeader, false);
    end;

    procedure SetSegmentFromFilter()
    var
        SegmentNo: Code[20];
    begin
        SegmentNo := GetFilterSegmentNo();
        if SegmentNo = '' then begin
            FilterGroup(2);
            SegmentNo := GetFilterSegmentNo();
            FilterGroup(0);
        end;
        if SegmentNo <> '' then
            Validate("Segment No.", SegmentNo);
    end;

    local procedure GetFilterSegmentNo(): Code[20]
    begin
        if GetFilter("Segment No.") <> '' then
            if GetRangeMin("Segment No.") = GetRangeMax("Segment No.") then
                exit(GetRangeMax("Segment No."));
    end;

    procedure SetContactFromFilter()
    var
        ContactNo: Code[20];
    begin
        ContactNo := GetFilterContactNo();
        if ContactNo = '' then begin
            FilterGroup(2);
            ContactNo := GetFilterContactNo();
            FilterGroup(0);
        end;
        if ContactNo <> '' then
            Validate("Contact No.", ContactNo);
    end;

    local procedure GetFilterContactNo(): Code[20]
    begin
        if (GetFilter("Contact No.") <> '') and (GetFilter("Contact No.") <> '<>''''') then
            if GetRangeMin("Contact No.") = GetRangeMax("Contact No.") then
                exit(GetRangeMax("Contact No."));
        if GetFilter("Contact Company No.") <> '' then
            if GetRangeMin("Contact Company No.") = GetRangeMax("Contact Company No.") then
                exit(GetRangeMax("Contact Company No."));
    end;

    procedure StartActivateFirstStage()
    var
        SalesCycleStage: Record "Sales Cycle Stage";
        OpportunityEntry: Record "Opportunity Entry";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ConfirmManagement.GetResponse(ActivateFirstStageQst, true) then begin
            TestField("Sales Cycle Code");
            TestField(Status, Status::"Not Started");
            SalesCycleStage.SetRange("Sales Cycle Code", "Sales Cycle Code");
            OnStartActivateFirstStageOnBeforeSalesCycleStageFind(Rec, SalesCycleStage);
            if SalesCycleStage.FindFirst() then begin
                OpportunityEntry.Init();
                OpportunityEntry."Sales Cycle Stage" := SalesCycleStage.Stage;
                OpportunityEntry."Sales Cycle Stage Description" := SalesCycleStage.Description;
                OpportunityEntry.InitOpportunityEntry(Rec);
                OpportunityEntry.InsertEntry(OpportunityEntry, false, true);
                OpportunityEntry.UpdateEstimates();
            end else
                Error(SalesCycleNotFoundErr);
        end;
        OnAfterStartActivateFirstStage(SalesCycleStage, OpportunityEntry, Rec);
    end;

    procedure SetDefaultSalesCycle()
    var
        SalesCycle: Record "Sales Cycle";
    begin
        RMSetup.Get();
        if RMSetup."Default Sales Cycle Code" <> '' then
            if SalesCycle.Get(RMSetup."Default Sales Cycle Code") then
                if not SalesCycle.Blocked then
                    "Sales Cycle Code" := RMSetup."Default Sales Cycle Code";
    end;

    local procedure SetDefaultSalesperson()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit;

        if UserSetup."Salespers./Purch. Code" <> '' then
            Validate("Salesperson Code", UserSetup."Salespers./Purch. Code");
    end;

    local procedure RunQuotePage(var SalesHeader: Record "Sales Header"; Modal: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunQuotePage(SalesHeader, Modal, IsHandled);
        if IsHandled then
            exit;

        if Modal then
            PAGE.RunModal(PAGE::"Sales Quote", SalesHeader)
        else
            PAGE.Run(PAGE::"Sales Quote", SalesHeader);
    end;

    local procedure LookupCampaigns()
    var
        Campaign: Record Campaign;
        Opportunity: Record Opportunity;
    begin
        Campaign.SetFilter("Starting Date", '..%1', "Creation Date");
        Campaign.SetFilter("Ending Date", '%1..', "Creation Date");
        Campaign.CalcFields(Activated);
        Campaign.SetRange(Activated, true);
        OnLookupCampaignsOnAfterSetFilters(Rec, Campaign);
        if PAGE.RunModal(0, Campaign) = ACTION::LookupOK then begin
            Opportunity := Rec;
            Opportunity.Validate("Campaign No.", Campaign."No.");
            Rec := Opportunity;
        end;
    end;

    local procedure LookupSegments()
    var
        SegmentHeader: Record "Segment Header";
    begin
        if "Campaign No." <> '' then
            SegmentHeader.SetRange("Campaign No.", "Campaign No.");
        if PAGE.RunModal(0, SegmentHeader) = ACTION::LookupOK then
            Validate("Segment No.", SegmentHeader."No.");
    end;

    local procedure CheckCampaign()
    var
        Campaign: Record Campaign;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCampaign(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Campaign No." <> '' then begin
            Campaign.Get("Campaign No.");
            if (Campaign."Starting Date" > "Creation Date") or (Campaign."Ending Date" < "Creation Date") then
                FieldError("Campaign No.");
            Campaign.CalcFields(Activated);
            Campaign.TestField(Activated, true);
        end;
    end;

    local procedure CheckSegmentCampaignNo()
    var
        SegmentHeader: Record "Segment Header";
    begin
        SegmentHeader.Get("Segment No.");
        if SegmentHeader."Campaign No." <> '' then
            SegmentHeader.TestField("Campaign No.", "Campaign No.");
    end;

    local procedure SetDefaultSegmentNo()
    var
        SegmentHeader: Record "Segment Header";
    begin
        "Segment No." := '';
        if "Campaign No." <> '' then begin
            SegmentHeader.SetRange("Campaign No.", "Campaign No.");
            if SegmentHeader.FindFirst() and (SegmentHeader.Count = 1) then
                "Segment No." := SegmentHeader."No."
        end;
    end;

    procedure SetCampaignFromFilter()
    var
        CampaignNo: Code[20];
    begin
        CampaignNo := GetFilterCampaignNo();
        if CampaignNo = '' then begin
            FilterGroup(2);
            CampaignNo := GetFilterCampaignNo();
            FilterGroup(0);
        end;
        if CampaignNo <> '' then
            Validate("Campaign No.", CampaignNo);
    end;

    local procedure GetFilterCampaignNo(): Code[20]
    begin
        if GetFilter("Campaign No.") <> '' then
            if GetRangeMin("Campaign No.") = GetRangeMax("Campaign No.") then
                exit(GetRangeMax("Campaign No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinishWizard(var Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertOpportunity(var Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterStartActivateFirstStage(SalesCycleStage: Record "Sales Cycle Stage"; var OpportunityEntry: Record "Opportunity Entry"; var Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetNewCustomerTemplateCode(Cont: Record Contact; var CustTemplateCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckStatus(var Opportunity: Record Opportunity; var OppEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCampaign(var Opportunity: Record Opportunity; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinishWizard(var Opportunity: Record Opportunity; var OpportunityEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessFirstStage(var Opportunity: Record Opportunity; var OpportunityEntry2: Record "Opportunity Entry"; ActivateFirstStage: Boolean; CalledForSegment: Boolean; SalesPersonCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPageForRec(var Opportunity: Record Opportunity; var PageID: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateOppFromOppOnAfterInit(var Opportunity: Record Opportunity; var DoSetDefaultSalesCycle: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateQuoteOnAfterSalesHeaderInsert(var SalesHeader: Record "Sales Header"; var Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateQuoteOnBeforeSalesHeaderInsert(var SalesHeader: Record "Sales Header"; var Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateQuoteOnBeforePageRun(var SalesHeader: Record "Sales Header"; var Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishWizardOnBeforeInsertOpportunity(var Opportunity: Record Opportunity; var OppEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupCampaignsOnAfterSetFilters(var Opportunity: Record Opportunity; var Campaign: Record Campaign)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateFromCreateFromInteractionLogEntryOnBeforeInsert(var Opportunity: Record Opportunity; InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateFromSegmentLineOnBeforeInsert(var Opportunity: Record Opportunity; SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunQuotePage(var SalesHeader: Record "Sales Header"; Modal: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOppFromOppOnBeforeSetFilterSalesPersonCode(var Opportunity: Record Opportunity; var IsHandled: Boolean; var FromOpportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessFirstStage(var OpportunityEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateContactNo(var Opportunity: Record Opportunity; CurrentFieldNo: Integer; var IsHandled: Boolean; xOpportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStartWizardBeforeInsert(var Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStartActivateFirstStageOnBeforeSalesCycleStageFind(var Opportunity: Record Opportunity; var SalesCycleStage: Record "Sales Cycle Stage")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOpportunity(var Opportunity: Record Opportunity)
    begin
    end;
}
