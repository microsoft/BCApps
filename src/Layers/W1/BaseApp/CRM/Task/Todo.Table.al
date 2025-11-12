// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Document;
using System;
using System.Azure.Identity;
using System.Environment;
using System.Globalization;
using System.Integration;
using System.Security.AccessControl;
using System.Email;

table 5080 "To-do"
{
    Caption = 'Task';
    DataCaptionFields = "No.", Description;
    DataClassification = CustomerContent;
    DrillDownPageID = "Task List";
    LookupPageID = "Task List";
    Permissions = tabledata "To-Do" = RI,
                  tabledata "Marketing Setup" = R,
                  tabledata "Team Salesperson" = R;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    RMSetup.Get();
                    NoSeries.TestManual(RMSetup."To-do Nos.");
                    "No. Series" := '';
                    if ("System To-do Type" = "System To-do Type"::Organizer) or
                       ("System To-do Type" = "System To-do Type"::Team)
                    then
                        UpdateAttendeeTasks(xRec."No.");
                end;
            end;
        }
        field(2; "Team Code"; Code[10])
        {
            Caption = 'Team Code';
            TableRelation = Team;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTeamCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if ("Team Code" <> xRec."Team Code") and
                   ("No." <> '') and
                   IsCalledFromForm()
                then begin
                    if ("Team Code" = '') and ("Salesperson Code" = '') then
                        Error(Text035, FieldCaption("Salesperson Code"), FieldCaption("Team Code"));
                    if xRec."Team Code" <> '' then begin
                        if Closed then begin
                            if Confirm(StrSubstNo(Text039, "No.", xRec."Team Code", "Team Code")) then begin
                                ChangeTeam();
                                Get("No.");
                                Validate(Closed, false);
                            end else
                                "Team Code" := xRec."Team Code"
                        end else
                            if Confirm(StrSubstNo(TasksWillBeDeletedQst, xRec."Team Code", "Team Code")) then
                                ChangeTeam()
                            else
                                "Team Code" := xRec."Team Code";
                    end else
                        if Closed then begin
                            if Confirm(StrSubstNo(Text042, "No.", "Team Code")) then begin
                                ReassignSalespersonTaskToTeam();
                                Get("No.");
                                Validate(Closed, false);
                            end else
                                "Team Code" := ''
                        end else
                            ReassignSalespersonTaskToTeam();
                end
            end;
        }
        field(3; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSalespersonCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if (xRec."Salesperson Code" <> "Salesperson Code") and
                   ("No." <> '') and
                   IsCalledFromForm()
                then begin
                    if ("Team Code" = '') and ("Salesperson Code" = '') then
                        Error(Text035, FieldCaption("Salesperson Code"), FieldCaption("Team Code"));
                    if (Type = Type::Meeting) and ("Team Code" = '') then
                        Error(Text009, FieldCaption("Salesperson Code"));

                    if "Team Code" <> '' then
                        if Type = Type::Meeting then
                            if Closed then
                                if Confirm(StrSubstNo(Text040, "No.", "Salesperson Code")) then begin
                                    ReassignTeamTaskToSalesperson();
                                    Get("No.");
                                    Validate(Closed, false);
                                end else
                                    "Salesperson Code" := xRec."Salesperson Code"
                            else
                                if Confirm(StrSubstNo(Text033, "No.", "Salesperson Code")) then
                                    ReassignTeamTaskToSalesperson()
                                else
                                    "Salesperson Code" := xRec."Salesperson Code"
                        else
                            if Closed then
                                if Confirm(StrSubstNo(Text041, "No.", "Salesperson Code")) then begin
                                    ReassignTeamTaskToSalesperson();
                                    Get("No.");
                                    Validate(Closed, false);
                                end else
                                    "Salesperson Code" := xRec."Salesperson Code"
                            else
                                ConfirmReassignmentOpenedNotMeetingToDo();
                end
            end;
        }
        field(4; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(5; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;

            trigger OnValidate()
            var
                TempAttendee: Record Attendee temporary;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateContactNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if Cont.Get("Contact No.") then
                    "Contact Company No." := Cont."Company No."
                else
                    Clear("Contact Company No.");

                if ("No." <> '') and
                   ("No." = "Organizer To-do No.") and
                   ("Contact No." <> xRec."Contact No.") and
                   (Type <> Type::Meeting)
                then
                    case true of
                        (xRec."Contact No." = '') and ("Contact No." <> ''):
                            begin
                                TempAttendee.CreateAttendee(
                                  TempAttendee,
                                  "No.", 10000, TempAttendee."Attendance Type"::Required,
                                  TempAttendee."Attendee Type"::Contact,
                                  "Contact No.", false);
                                CreateSubTask(TempAttendee, Rec);
                            end;
                        (xRec."Contact No." <> '') and ("Contact No." = ''):
                            begin
                                TempAttendee.CreateAttendee(
                                  TempAttendee,
                                  "No.", 10000, TempAttendee."Attendance Type"::Required,
                                  TempAttendee."Attendee Type"::Contact,
                                  xRec."Contact No.", false);
                                DeleteAttendeeTask(TempAttendee);
                            end;
                        xRec."Contact No." <> "Contact No.":
                            begin
                                TempAttendee.CreateAttendee(
                                  TempAttendee,
                                  "No.", 10000, TempAttendee."Attendance Type"::Required,
                                  TempAttendee."Attendee Type"::Contact,
                                  xRec."Contact No.", false);
                                DeleteAttendeeTask(TempAttendee);
                                TempAttendee.CreateAttendee(
                                  TempAttendee,
                                  "No.", 20000, TempAttendee."Attendance Type"::Required,
                                  TempAttendee."Attendee Type"::Contact,
                                  "Contact No.", false);
                                CreateSubTask(TempAttendee, Rec);
                            end;
                    end;
            end;
        }
        field(6; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;

            trigger OnValidate()
            var
                OppEntry: Record "Opportunity Entry";
            begin
                OppEntry.Reset();
                OppEntry.SetCurrentKey(Active, "Opportunity No.");
                OppEntry.SetRange(Active, true);
                OppEntry.SetRange("Opportunity No.", "Opportunity No.");
                if OppEntry.FindFirst() then
                    "Opportunity Entry No." := OppEntry."Entry No."
                else
                    "Opportunity Entry No." := 0;
            end;
        }
        field(7; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
            TableRelation = "Segment Header";
        }
        field(8; Type; Enum "Task Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                EnvironmentInfo: Codeunit "Environment Information";
                OldEndDate: Date;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateType(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if EnvironmentInfo.IsSaaS() and (Type = Type::Meeting) then
                    Error(MeetingSaaSNotSupportedErr);

                if "No." <> '' then begin
                    if ((xRec.Type = Type::Meeting) and (Type <> Type::Meeting)) or
                       ((xRec.Type <> Type::Meeting) and (Type = Type::Meeting))
                    then
                        Error(Text012);
                end else begin
                    if CurrFieldNo = 0 then
                        exit;

                    if not IsMeetingOrPhoneCall(xRec.Type) then
                        TempEndDateTime := CreateDateTime(xRec.Date, xRec."Start Time") - OneDayDuration() + xRec.Duration
                    else
                        TempEndDateTime := CreateDateTime(xRec.Date, xRec."Start Time") + xRec.Duration;

                    OldEndDate := DT2Date(TempEndDateTime);

                    if IsMeetingOrPhoneCall(xRec.Type) and not IsMeetingOrPhoneCall(Rec.Type) then begin
                        "Start Time" := 0T;
                        "All Day Event" := false;
                        SetDuration(OldEndDate, 0T);
                    end;

                    if not IsMeetingOrPhoneCall(xRec.Type) and IsMeetingOrPhoneCall(Rec.Type) then begin
                        "Start Time" := 0T;
                        if OldEndDate = Date then
                            SetDuration(OldEndDate, DT2Time(CreateDateTime(OldEndDate, 0T) + 30 * 60 * 1000))
                        else
                            SetDuration(OldEndDate, 0T);
                    end;
                end;
            end;
        }
        field(9; Date; Date)
        {
            Caption = 'Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                if (Date < DMY2Date(1, 1, 1900)) or (Date > DMY2Date(31, 12, 2999)) then
                    Error(Text006, DMY2Date(1, 1, 1900), DMY2Date(31, 12, 2999));

                if Date <> xRec.Date then
                    GetEndDateTime();
            end;
        }
        field(10; Status; Enum "Task Status")
        {
            Caption = 'Status';

            trigger OnValidate()
            begin
                if Status = Status::Completed then
                    Validate(Closed, true)
                else
                    Validate(Closed, false);
            end;
        }
        field(11; Priority; Option)
        {
            Caption = 'Priority';
            InitValue = Normal;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; Closed; Boolean)
        {
            Caption = 'Closed';

            trigger OnValidate()
            var
                IsHandled: Boolean;
                SkipConfirmDialog: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateClosed(Rec, xRec, SkipConfirmDialog, IsHandled);
                if IsHandled then
                    exit;

                if Closed then begin
                    "Date Closed" := Today;
                    Status := Status::Completed;
                    if not Canceled then begin
                        if ("Team Code" <> '') and
                           ("Completed By" = '')
                        then
                            Error(Text029, FieldCaption("Completed By"));
                        if CurrFieldNo <> 0 then
                            if not SkipConfirmDialog then
                                if Confirm(Text004, true) then
                                    CreateInteraction()
                    end;
                    if Recurring then
                        CreateRecurringTask();
                end else begin
                    Canceled := false;
                    "Date Closed" := 0D;
                    if Status = Status::Completed then
                        Status := Status::"In Progress";
                    if "Completed By" <> '' then
                        "Completed By" := ''
                end;
                if CurrFieldNo <> 0 then
                    Modify(true);
            end;
        }
        field(14; "Date Closed"; Date)
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
            CalcFormula = exist("Rlshp. Mgt. Comment Line" where("Table Name" = const("To-do"),
                                                                  "No." = field("Organizer To-do No."),
                                                                  "Sub No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; Canceled; Boolean)
        {
            Caption = 'Canceled';

            trigger OnValidate()
            begin
                if Canceled and not Closed then
                    Validate(Closed, true);
                if (not Canceled) and Closed then
                    Validate(Closed, false);
            end;
        }
        field(18; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Team Name"; Text[50])
        {
            CalcFormula = lookup(Team.Name where(Code = field("Team Code")));
            Caption = 'Team Name';
            Editable = false;
            FieldClass = FlowField;
            NotBlank = false;
        }
        field(20; "Salesperson Name"; Text[50])
        {
            CalcFormula = lookup("Salesperson/Purchaser".Name where(Code = field("Salesperson Code")));
            Caption = 'Salesperson Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; "Campaign Description"; Text[100])
        {
            CalcFormula = lookup(Campaign.Description where("No." = field("Campaign No.")));
            Caption = 'Campaign Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "Contact Company No."; Code[20])
        {
            Caption = 'Contact Company No.';
            TableRelation = Contact where(Type = const(Company));
        }
        field(23; "Contact Company Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact Company No.")));
            Caption = 'Contact Company Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; Recurring; Boolean)
        {
            Caption = 'Recurring';
        }
        field(25; "Recurring Date Interval"; DateFormula)
        {
            Caption = 'Recurring Date Interval';

            trigger OnValidate()
            begin
                if Recurring then
                    TestField("Recurring Date Interval");
            end;
        }
        field(26; "Calc. Due Date From"; Option)
        {
            Caption = 'Calc. Due Date From';
            OptionCaption = ' ,Due Date,Closing Date';
            OptionMembers = " ","Due Date","Closing Date";

            trigger OnValidate()
            begin
                if Recurring then
                    TestField("Calc. Due Date From");
            end;
        }
        field(27; "Opportunity Description"; Text[100])
        {
            CalcFormula = lookup(Opportunity.Description where("No." = field("Opportunity No.")));
            Caption = 'Opportunity Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Start Time"; Time)
        {
            Caption = 'Start Time';

            trigger OnValidate()
            begin
                if "Start Time" <> xRec."Start Time" then
                    GetEndDateTime();
            end;
        }
        field(29; Duration; Duration)
        {
            Caption = 'Duration';

            trigger OnValidate()
            begin
                if Duration < 0 then
                    Error(Text005);

                if Duration < (60 * 1000) then
                    Error(Text007);

                if Duration > (CreateDateTime(Today + 3650, 0T) - CreateDateTime(Today, 0T)) then
                    Error(Text008);

                if Duration <> xRec.Duration then
                    GetEndDateTime();
            end;
        }
        field(31; "Opportunity Entry No."; Integer)
        {
            Caption = 'Opportunity Entry No.';
            TableRelation = "Opportunity Entry";
        }
        field(32; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
        }
        field(33; "Last Time Modified"; Time)
        {
            Caption = 'Last Time Modified';
        }
        field(34; "All Day Event"; Boolean)
        {
            Caption = 'All Day Event';

            trigger OnValidate()
            begin
                if "All Day Event" then begin
                    "Start Time" := 0T;
                    TempStartDateTime := CreateDateTime(Date, "Start Time");
                    TempEndDateTime := TempStartDateTime + Duration;
                    if DT2Date(TempEndDateTime) = Date then
                        Duration := 1440 * 1000 * 60
                    else
                        Duration := RoundDateTime(TempEndDateTime + 1, 1440 * 1000 * 60, '>') - TempStartDateTime;
                end else
                    Duration := Duration - 1440 * 1000 * 60;
            end;
        }
        field(35; Location; Text[100])
        {
            Caption = 'Location';
        }
        field(36; "Organizer To-do No."; Code[20])
        {
            Caption = 'Organizer Task No.';
            TableRelation = "To-do";
        }
        field(37; "Interaction Template Code"; Code[10])
        {
            Caption = 'Interaction Template Code';
            TableRelation = "Interaction Template";

            trigger OnValidate()
            var
                TaskInteractionLanguage: Record "To-do Interaction Language";
                Attachment: Record Attachment;
            begin
                if "No." <> '' then
                    UpdateInteractionTemplate(
                      Rec, TaskInteractionLanguage, Attachment, "Interaction Template Code", false);
            end;
        }
        field(38; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnLookup()
            var
                TaskInteractionLanguage: Record "To-do Interaction Language";
            begin
                Modify();
                Commit();

                TaskInteractionLanguage.SetRange("To-do No.", "Organizer To-do No.");
                if TaskInteractionLanguage.Get("Organizer To-do No.", "Language Code") then;
                if PAGE.RunModal(0, TaskInteractionLanguage) = ACTION::LookupOK then begin
                    if ("System To-do Type" = "System To-do Type"::Organizer) or
                       ("System To-do Type" = "System To-do Type"::Team)
                    then
                        if not TaskInteractionLanguage.IsEmpty() then begin
                            "Language Code" := TaskInteractionLanguage."Language Code";
                            "Attachment No." := TaskInteractionLanguage."Attachment No.";
                        end else begin
                            "Language Code" := '';
                            "Attachment No." := 0;
                        end;
                end else
                    if not TaskInteractionLanguage.IsEmpty() then begin
                        if "Language Code" = TaskInteractionLanguage."Language Code" then
                            "Attachment No." := TaskInteractionLanguage."Attachment No.";
                    end else begin
                        "Language Code" := '';
                        "Attachment No." := 0;
                    end;
            end;

            trigger OnValidate()
            var
                TaskInteractionLanguage: Record "To-do Interaction Language";
            begin
                if CurrFieldNo <> 0 then
                    Modify();

                if "Language Code" = xRec."Language Code" then
                    exit;

                if not TaskInteractionLanguage.Get("No.", "Language Code") then begin
                    if "No." = '' then
                        exit;
                    if CurrFieldNo <> 0 then
                        if Confirm(Text010, true, TaskInteractionLanguage.TableCaption(), "Language Code") then begin
                            TaskInteractionLanguage.Init();
                            TaskInteractionLanguage."To-do No." := "No.";
                            TaskInteractionLanguage."Language Code" := "Language Code";
                            TaskInteractionLanguage.Description := Format("Interaction Template Code") + ' ' + Format("Language Code");
                            TaskInteractionLanguage.Insert(true);
                            "Attachment No." := 0;
                            Modify();
                        end else
                            Error('');
                end else
                    "Attachment No." := TaskInteractionLanguage."Attachment No.";
            end;
        }
        field(39; "Attachment No."; Integer)
        {
            Caption = 'Attachment No.';
        }
        field(40; Subject; Text[100])
        {
            Caption = 'Subject';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    Modify();
            end;
        }
        field(41; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
            DecimalPlaces = 2 : 2;

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    Modify();
            end;
        }
        field(42; "Unit Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit Duration (Min.)';
            DecimalPlaces = 0 : 2;

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    Modify();
            end;
        }
        field(43; "No. of Attendees"; Integer)
        {
            CalcFormula = count(Attendee where("To-do No." = field("Organizer To-do No.")));
            Caption = 'No. of Attendees';
            Editable = false;
            FieldClass = FlowField;
        }
        field(44; "Attendees Accepted No."; Integer)
        {
            CalcFormula = count(Attendee where("To-do No." = field("Organizer To-do No."),
                                                "Invitation Response Type" = const(Accepted)));
            Caption = 'Attendees Accepted No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(45; "System To-do Type"; Option)
        {
            Caption = 'System Task Type';
            OptionCaption = 'Organizer,Salesperson Attendee,Contact Attendee,Team';
            OptionMembers = Organizer,"Salesperson Attendee","Contact Attendee",Team;
        }
        field(46; "Completed By"; Code[20])
        {
            Caption = 'Completed By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Salesperson/Purchaser".Code;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCompletedBy(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if (xRec."Completed By" = '') and
                   ("Completed By" <> '')
                then
                    if Confirm(Text034) then
                        Validate(Closed, true)
                    else
                        "Completed By" := '';
            end;
        }
        field(47; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                if "Ending Date" <> xRec."Ending Date" then
                    SetDuration("Ending Date", "Ending Time");
            end;
        }
        field(48; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            begin
                if "Ending Time" <> xRec."Ending Time" then
                    SetDuration("Ending Date", "Ending Time");
            end;
        }
        field(9501; "Wizard Step"; Option)
        {
            Caption = 'Wizard Step';
            Editable = false;
            OptionCaption = ' ,1,2,3,4,5,6';
            OptionMembers = " ","1","2","3","4","5","6";
        }
        field(9504; "Team To-do"; Boolean)
        {
            Caption = 'Team Task';
        }
        field(9505; "Send on finish"; Boolean)
        {
            Caption = 'Send on finish';
        }
        field(9506; "Segment Description"; Text[100])
        {
            Caption = 'Segment Description';
        }
        field(9507; "Team Meeting Organizer"; Code[20])
        {
            Caption = 'Team Meeting Organizer';
        }
        field(9508; "Activity Code"; Code[10])
        {
            Caption = 'Activity Code';
            TableRelation = Activity.Code;
        }
        field(9509; "Wizard Contact Name"; Text[100])
        {
            Caption = 'Wizard Contact Name';
        }
        field(9510; "Wizard Campaign Description"; Text[100])
        {
            Caption = 'Wizard Campaign Description';
        }
        field(9511; "Wizard Opportunity Description"; Text[100])
        {
            Caption = 'Wizard Opportunity Description';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Contact Company No.", Date, "Contact No.", Closed)
        {
        }
        key(Key3; "Contact Company No.", "Contact No.", Closed, Date)
        {
        }
        key(Key4; "Salesperson Code", Date, Closed)
        {
        }
        key(Key5; "Team Code", Date, Closed)
        {
        }
        key(Key6; "Campaign No.", Date)
        {
        }
        key(Key7; "Segment No.", Date)
        {
        }
        key(Key8; "Opportunity No.", Date, Closed)
        {
        }
        key(Key9; "Organizer To-do No.", "System To-do Type")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, Status)
        {
        }
    }

    trigger OnDelete()
    var
        Attendee: Record Attendee;
        Task: Record "To-do";
        TaskInteractionLanguage: Record "To-do Interaction Language";
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
    begin
        RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::"To-do");
        RMCommentLine.SetRange("No.", "No.");
        RMCommentLine.DeleteAll();
        Task.SetRange("Organizer To-do No.", "No.");
        Task.SetFilter("No.", '<>%1', "No.");
        if Task.FindFirst() then
            Task.DeleteAll();

        Attendee.SetRange("To-do No.", "No.");
        Attendee.DeleteAll();

        TaskInteractionLanguage.SetRange("To-do No.", "No.");
        TaskInteractionLanguage.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            RMSetup.Get();
            RMSetup.TestField("To-do Nos.");
            if NoSeries.AreRelated(RMSetup."To-do Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := RMSetup."To-do Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
        if (("System To-do Type" = "System To-do Type"::Organizer) and
            ("Team Code" = '')) or
           ("System To-do Type" = "System To-do Type"::Team)
        then
            "Organizer To-do No." := "No.";
        "Last Date Modified" := Today;
        "Last Time Modified" := Time;
    end;

    trigger OnModify()
    begin
        if "No." <> '' then begin
            "Last Date Modified" := Today;
            "Last Time Modified" := Time;

            UpdateAttendeeTasks("No.");
        end;
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be specified.';
        Text001: Label '%1 No. %2 has been created from recurring %3 %4.';
#pragma warning restore AA0470
        Text002: Label 'Do you want to create a Task for all contacts in the %1 Segment', Comment = '%1 = Segment Header No.';
        Text003: Label 'Do you want to assign an activity to all Contacts in the %1 Segment', Comment = '%1 = Segment Header No.';
#pragma warning restore AA0074
        RMSetup: Record "Marketing Setup";
        Cont: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Activity: Record Activity;
        Campaign: Record Campaign;
        Team: Record Team;
        Opp: Record Opportunity;
        SegHeader: Record "Segment Header";
        TempAttendee: Record Attendee temporary;
        NoSeries: Codeunit "No. Series";
#pragma warning disable AA0074
        Text004: Label 'Do you want to register an Interaction Log Entry?';
        Text005: Label 'Information that you have entered in this field will cause the duration to be negative which is not allowed. Please modify the ending date/time value.';
#pragma warning disable AA0470
        Text006: Label 'The valid range of dates is from %1 to %2. Please enter a date within this range.';
#pragma warning restore AA0470
        Text007: Label 'Information that you have entered in this field will cause the duration to be less than 1 minute, which is not allowed. Please modify the ending date/time value.';
        Text008: Label 'Information that you have entered in this field will cause the duration to be more than 10 years, which is not allowed. Please modify the ending date/time value.';
        Text009: Label 'You cannot change the %1 for this Task, because this salesperson is the meeting organizer.', Comment = '%1=Salesperson Code';
        Text010: Label 'Do you want to create a new %2 value in %1 for this Task?', Comment = '%1=Task Interaction Language,%2=Language Code';
        Text012: Label 'You cannot change a Task type from Blank or Phone Call to Meeting and vice versa. You can only change a Task type from Blank to Phone Call or from Phone Call to Blank.';
#pragma warning disable AA0470
        Text015: Label 'Dear %1,';
#pragma warning restore AA0470
        Text016: Label 'You are cordially invited to attend the meeting, which will take place on %1, %2 at %3.', Comment = '%1 = Task Date,%2 = Task StartTime,%3=Task location';
        Text017: Label 'Yours sincerely,';
#pragma warning disable AA0470
        Text018: Label 'The %1 check box is not selected.';
        Text019: Label 'Send invitations to all Attendees with selected %1 check boxes.';
#pragma warning restore AA0470
        Text020: Label 'Send invitations to Attendees who have not been sent invitations yet.';
        Text021: Label 'Do not send invitations.';
#pragma warning disable AA0470
        Text022: Label 'Invitations have already been sent to Attendees with selected %1 check boxes. Do you want to resend the invitations?';
        Text023: Label 'Outlook failed to send an invitation to %1.';
#pragma warning restore AA0470
        Text029: Label 'The %1 field must be filled in for Tasks assigned to a team.', Comment = '%1=Completed By';
#pragma warning restore AA0074
        TasksWillBeDeletedQst: Label 'Tasks of the %1 team members who do not belong to the %2 team will be deleted. Do you want to continue?', Comment = '%1 = old Team code, %2 = new Team code';
#pragma warning disable AA0074
        Text032: Label 'Task No. %1 will be reassigned to %2 and the corresponding salesperson Tasks for team members will be deleted. Do you want to continue?', Comment = '%1=Task No.,%2=Salesperson Code';
        Text033: Label 'Task No. %1 will be reassigned to %2. Do you want to continue?', Comment = '%1=Task No.,%2=Salesperson Code';
        Text034: Label 'Do you want to close the Task?';
#pragma warning disable AA0470
        Text035: Label 'You must fill in either the %1 field or the %2 field.';
#pragma warning restore AA0470
        Text036: Label 'Creating Tasks...\';
#pragma warning restore AA0074
        TaskNoMsg: Label 'Task No. #1##############\', Comment = '%1 = counter';
#pragma warning disable AA0074
        Text038: Label 'Status    @2@@@@@@@@@@@@@@';
        Text039: Label 'Task No. %1 is closed and will be reopened. The Tasks of the %2 team members who do not belong to the %3 team will be deleted. Do you want to continue?', Comment = '%1=Task No,%2=Team Code,%3=Team Code';
        Text040: Label 'Task No. %1 is closed and will be reopened. It will be reassigned to %2, and the corresponding salesperson Tasks for team members will be deleted. Do you want to continue?', Comment = '%1=Task No.,%2=Salesperson Code';
        Text041: Label 'Task No. %1 is closed. It will be reopened and reassigned to %2. Do you want to continue?', Comment = '%1=Task No.,%2=Salesperson Code';
        Text042: Label 'Task No. %1 is closed. Do you want to reopen it and assign to the %2 team?', Comment = '%1=Task No.,%2=Team Code';
#pragma warning disable AA0470
        Text043: Label 'You must fill in the %1 field.';
#pragma warning restore AA0470
        Text047: Label 'You cannot use the wizard to create an attachment. You can create an attachment in the Interaction Template window.';
        Text051: Label 'Activity Code';
#pragma warning disable AA0470
        Text053: Label 'You must specify %1 or %2.';
#pragma warning restore AA0470
        Text056: Label 'Activity %1 contains Tasks of type Meeting. You must fill in the Meeting Organizer field.', Comment = '%1=Activity Code';
        Text065: Label 'You must specify the Task organizer.';
#pragma warning disable AA0470
        Text067: Label 'The %1 must contain an attachment if you want to send an invitation to an %2 of the contact type.';
        Text068: Label 'You cannot select the Send invitation(s) on Finish check box, because none of the %1 check boxes are selected.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        RunFormCode: Boolean;
        CreateExchangeAppointment: Boolean;
        MeetingSaaSNotSupportedErr: Label 'You cannot create a task of type Meeting because you''re not using an on-premises deployment.';

    protected var
        TempTaskInteractionLanguage: Record "To-do Interaction Language" temporary;
        TempAttachment: Record Attachment temporary;
        TempRMCommentLine: Record "Rlshp. Mgt. Comment Line" temporary;
        TempEndDateTime: DateTime;
        TempStartDateTime: DateTime;

    procedure CreateTaskFromTask(var Task: Record "To-do")
    begin
        DeleteAll();
        Init();
        SetFilterFromTask(Task);

        OnCreateTaskFromTaskOnBeforeStartWizard(Rec, Task);
        StartWizard();
    end;

    procedure CreateTaskFromSalesHeader(SalesHeader: Record "Sales Header")
    begin
        DeleteAll();
        Init();
        Validate("Contact No.", SalesHeader."Sell-to Contact No.");
        SetRange("Contact No.", SalesHeader."Sell-to Contact No.");
        if SalesHeader."Salesperson Code" <> '' then begin
            "Salesperson Code" := SalesHeader."Salesperson Code";
            SetRange("Salesperson Code", "Salesperson Code");
        end;
        if SalesHeader."Campaign No." <> '' then begin
            "Campaign No." := SalesHeader."Campaign No.";
            SetRange("Campaign No.", "Campaign No.");
        end;

        OnCreateTaskFromSalesHeaderOnBeforeStartWizard(Rec, SalesHeader);
        OnCreateTaskFromSalesHeaderoOnBeforeStartWizard(Rec, SalesHeader); // Obsolete
        StartWizard();
    end;

    procedure CreateTaskFromInteractLogEntry(InteractionLogEntry: Record "Interaction Log Entry")
    begin
        Init();
        Validate("Contact No.", InteractionLogEntry."Contact No.");
        "Salesperson Code" := InteractionLogEntry."Salesperson Code";
        "Campaign No." := InteractionLogEntry."Campaign No.";

        OnCreateTaskFromInteractLogEntryOnBeforeStartWizard(Rec, InteractionLogEntry);
        StartWizard();
    end;

    local procedure CreateInteraction()
    var
        TempSegLine: Record "Segment Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateInteraction(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::"Phone Call" then begin
            TempSegLine."Campaign No." := "Campaign No.";
            TempSegLine."Opportunity No." := "Opportunity No.";
            TempSegLine."Contact No." := "Contact No.";
            TempSegLine."To-do No." := "No.";
            TempSegLine."Salesperson Code" := "Salesperson Code";

            OnCreateInteractionOnBeforeCreatePhoneCall(TempSegLine, Rec);
            TempSegLine.CreatePhoneCall();
        end else
            TempSegLine.CreateInteractionFromTask(Rec);
    end;

    local procedure CreateRecurringTask()
    var
        Task2: Record "To-do";
        TaskInteractLanguage: Record "To-do Interaction Language";
        Attachment: Record Attachment;
        Attendee: Record Attendee;
        TempAttendee: Record Attendee temporary;
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
        RMCommentLine3: Record "Rlshp. Mgt. Comment Line";
    begin
        TestField("Recurring Date Interval");
        if "Calc. Due Date From" = "Calc. Due Date From"::" " then
            Error(Text000, FieldCaption("Calc. Due Date From"));

        Task2 := Rec;
        Task2.Status := Task2.Status::"Not Started";
        Task2.Closed := false;
        Task2.Canceled := false;
        Task2."Date Closed" := 0D;
        Task2."Completed By" := '';
        case Task2."Calc. Due Date From" of
            Task2."Calc. Due Date From"::"Due Date":
                Task2.Date := CalcDate(Task2."Recurring Date Interval", Task2.Date);
            Task2."Calc. Due Date From"::"Closing Date":
                Task2.Date := CalcDate(Task2."Recurring Date Interval", Today);
        end;
        Task2.GetEndDateTime();

        RMCommentLine3.Reset();
        RMCommentLine3.SetRange("Table Name", RMCommentLine."Table Name"::"To-do");
        RMCommentLine3.SetRange("No.", Task2."No.");
        RMCommentLine3.SetRange("Sub No.", 0);

        TaskInteractLanguage.SetRange("To-do No.", Task2."No.");

        if Task2.Type = Task2.Type::Meeting then begin
            Attendee.SetRange("To-do No.", Task2."No.");
            Task2.Get(InsertTaskAndRelatedData(
                Task2, TaskInteractLanguage, Attachment, Attendee, RMCommentLine3));
        end else begin
            CreateAttendeesFromTask(TempAttendee, Task2, '');
            Task2.Get(InsertTaskAndRelatedData(
                Task2, TaskInteractLanguage, Attachment, TempAttendee, RMCommentLine3));
        end;

        Message(
          StrSubstNo(Text001,
            TableCaption, Task2."Organizer To-do No.", TableCaption(), "No."));
    end;

    procedure InsertTask(Task2: Record "To-do"; var RMCommentLine: Record "Rlshp. Mgt. Comment Line"; var TempAttendee: Record Attendee temporary; var TaskInteractionLanguage: Record "To-do Interaction Language"; var TempAttachment: Record Attachment temporary; ActivityCode: Code[10]; Deliver: Boolean)
    var
        SegHeader: Record "Segment Header";
        SegLine: Record "Segment Line";
        ConfirmText: Text[250];
    begin
        if SegHeader.Get(GetFilter("Segment No.")) then begin
            SegLine.SetRange("Segment No.", SegHeader."No.");
            SegLine.SetFilter("Contact No.", '<>%1', '');
            if SegLine.FindFirst() then begin
                if ActivityCode = '' then
                    ConfirmText := Text002
                else
                    ConfirmText := Text003;
                if Confirm(ConfirmText, true, SegHeader."No.") then
                    if ActivityCode = '' then begin
                        Task2.Get(InsertTaskAndRelatedData(
                            Task2, TaskInteractionLanguage, TempAttachment, TempAttendee, RMCommentLine));
                        if (Task2.Type = Type::Meeting) and Deliver then
                            SendMAPIInvitations(Task2, true);
                    end else
                        InsertActivityTask(Task2, ActivityCode, TempAttendee);
            end;
        end else
            if ActivityCode = '' then begin
                Task2.Get(InsertTaskAndRelatedData(
                    Task2, TaskInteractionLanguage, TempAttachment, TempAttendee, RMCommentLine));
                if (Task2.Type = Type::Meeting) and Deliver then
                    SendMAPIInvitations(Task2, true);
            end else
                InsertActivityTask(Task2, ActivityCode, TempAttendee);

        if (Task2.Type = Task2.Type::Meeting) and
           Task2.Get(Task2."Organizer To-do No.")
        then
            Task2.ArrangeOrganizerAttendee();

        OnAfterInsertTask(Task2);
    end;

    local procedure InsertTaskAndRelatedData(Task2: Record "To-do"; var TaskInteractLanguage: Record "To-do Interaction Language"; var Attachment: Record Attachment; var Attendee: Record Attendee; var RMCommentLine: Record "Rlshp. Mgt. Comment Line") TaskNo: Code[20]
    var
        TaskInteractLanguage2: Record "To-do Interaction Language";
        TempAttendee: Record Attendee temporary;
        Task: Record "To-do";
        Attendee2: Record Attendee;
        Window: Dialog;
        AttendeeCounter: Integer;
        TotalAttendees: Integer;
        CommentLineInserted: Boolean;
        SkipTaskType: Boolean;
    begin
        SkipTaskType := false;
        OnBeforeInsertTaskAndRelatedData(Task2, SkipTaskType);
        if not SkipTaskType then
            if Task2."Team Code" = '' then
                Task2."System To-do Type" := "System To-do Type"::Organizer
            else
                Task2."System To-do Type" := "System To-do Type"::Team;

        if Task2.Type = Type::Meeting then begin
            Clear(Task2."No.");
            if Task2."System To-do Type" = Task2."System To-do Type"::Team then
                Task2."Salesperson Code" := '';
            Task2.Insert(true);

            CreateTaskInteractLanguages(TaskInteractLanguage, Attachment, Task2."No.");
            if TaskInteractLanguage2.Get(Task2."No.", Task2."Language Code") then begin
                Task2."Attachment No." := TaskInteractLanguage2."Attachment No.";
                Task2.Modify();
            end;

            if "Team Code" <> '' then begin
                Attendee.SetCurrentKey("To-do No.", "Attendance Type");
                Attendee.SetRange("Attendance Type", Attendee."Attendance Type"::"To-do Organizer");
                if Attendee.Find('-') then begin
                    CreateSubTask(Attendee, Task2);
                    Attendee2.Init();
                    Attendee2 := Attendee;
                    Attendee2."To-do No." := Task2."No.";
                    Attendee2.Insert();
                end;
                Attendee.SetFilter("Attendance Type", '<>%1', Attendee."Attendance Type"::"To-do Organizer")
            end;
            if Attendee.Find('-') then
                repeat
                    CreateSubTask(Attendee, Task2);
                    Attendee2.Init();
                    Attendee2 := Attendee;
                    Attendee2."To-do No." := Task2."No.";
                    Attendee2.Insert();
                until Attendee.Next() = 0;

            Task2.GetMeetingOrganizerTask(Task);
            TaskNo := Task."No."
        end else
            if Task2."Segment No." = '' then begin
                Clear(Task2."No.");

                Task2.Insert(true);
                TaskNo := Task2."No.";
                if Task2."System To-do Type" = "System To-do Type"::Team then begin
                    CreateOrganizerTask(Task2, TempAttendee, Task2."No.");
                    CreateAttendeesSubTask(Attendee, Task2);
                end;
            end else
                if Attendee.Find('-') then begin
                    Window.Open(Text036 + TaskNoMsg + Text038);
                    TotalAttendees := Attendee.Count();
                    repeat
                        if Task2."System To-do Type" = "System To-do Type"::Team then begin
                            Task.Init();
                            Task := Task2;
                            Clear(Task."No.");
                            FillSalesPersonContact(Task, Attendee);
                            Task.Insert(true);
                            TaskNo := Task."No.";
                            TempAttendee.Init();
                            TempAttendee := Attendee;
                            TempAttendee.Insert();
                            CreateSubTask(TempAttendee, Task);
                            TempAttendee.DeleteAll();
                            CreateOrganizerTask(Task, TempAttendee, "No.");
                        end else begin
                            Task.Init();
                            Task := Task2;
                            Clear(Task."No.");
                            Task."System To-do Type" := "System To-do Type"::Organizer;
                            FillSalesPersonContact(Task, Attendee);
                            Task.Insert(true);
                            TaskNo := Task."No.";

                            TempAttendee.Init();
                            TempAttendee := Attendee;
                            TempAttendee.Insert();
                            CreateSubTask(TempAttendee, Task);
                        end;
                        AttendeeCounter := AttendeeCounter + 1;
                        CreateCommentLines(RMCommentLine, TaskNo);
                        Window.Update(1, Task."Organizer To-do No.");
                        Window.Update(2, Round(AttendeeCounter / TotalAttendees * 10000, 1));
                        Commit();
                    until Attendee.Next() = 0;
                    Window.Close();
                    CommentLineInserted := true;
                end;
        if not CommentLineInserted then
            CreateCommentLines(RMCommentLine, Task2."No.");

        OnAfterInsertTaskAndRelatedData(Task2, TaskNo);
    end;

    local procedure CreateOrganizerTask(Task: Record "To-do"; var TempAttendee: Record Attendee temporary; TaskNo: Code[20])
    var
        TeamSalesperson: Record "Team Salesperson";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateOrganizerTask(Task, TempAttendee, TaskNo, IsHandled);
        if IsHandled then
            exit;

        TeamSalesperson.SetRange("Team Code", Task."Team Code");
        if TeamSalesperson.Find('-') then
            repeat
                TempAttendee.CreateAttendee(
                    TempAttendee,
                    TaskNo, 10000,
                    TempAttendee."Attendance Type"::"To-do Organizer",
                    TempAttendee."Attendee Type"::Salesperson,
                    TeamSalesperson."Salesperson Code",
                    true);
                CreateSubTask(TempAttendee, Task);
                TempAttendee.DeleteAll();
            until TeamSalesperson.Next() = 0
    end;

    procedure CreateSubTask(var Attendee: Record Attendee; Task: Record "To-do"): Code[20]
    var
        Task2: Record "To-do";
        TaskNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSubTask(Attendee, Task, TaskNo, IsHandled);
        if IsHandled then
            exit(TaskNo);

        Task2.Init();
        Task2.TransferFields(Task, false);

        if Attendee."Attendance Type" <> Attendee."Attendance Type"::"To-do Organizer" then begin
            if Attendee."Attendee Type" = Attendee."Attendee Type"::Salesperson then begin
                Task2.Validate("Salesperson Code", Attendee."Attendee No.");
                Task2."Organizer To-do No." := Task."No.";
                Task2."System To-do Type" := "System To-do Type"::"Salesperson Attendee";
            end else begin
                Task2.Validate("Salesperson Code", Task."Salesperson Code");
                Task2.Validate("Team Code", Task."Team Code");
                Task2.Validate("Contact No.", Attendee."Attendee No.");
                Task2."Organizer To-do No." := Task."No.";
                Task2."System To-do Type" := "System To-do Type"::"Contact Attendee";
            end;
            Task2.Insert(true)
        end else
            if Task."Team Code" <> '' then begin
                Task2."System To-do Type" := Task2."System To-do Type"::Organizer;
                Task2.Validate("Salesperson Code", Attendee."Attendee No.");
                Task2.Insert(true);
            end;
        exit(Task2."No.")
    end;

    procedure DeleteAttendeeTask(Attendee: Record Attendee)
    var
        Task: Record "To-do";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteAttendeeTask(Rec, IsHandled);
        if IsHandled then
            exit;

        if FindAttendeeTask(Task, Attendee) then
            Task.Delete();
    end;

    procedure FindAttendeeTask(var Task: Record "To-do"; Attendee: Record Attendee): Boolean
    begin
        Task.Reset();
        Task.SetCurrentKey("Organizer To-do No.", "System To-do Type");
        Task.SetRange("Organizer To-do No.", Attendee."To-do No.");
        if Attendee."Attendee Type" = Attendee."Attendee Type"::Contact then begin
            Task.SetRange("System To-do Type", Task."System To-do Type"::"Contact Attendee");
            Task.SetRange("Contact No.", Attendee."Attendee No.")
        end else begin
            Task.SetRange("System To-do Type", Task."System To-do Type"::"Salesperson Attendee");
            Task.SetRange("Salesperson Code", Attendee."Attendee No.");
        end;
        exit(Task.Find('-'));
    end;

    local procedure CreateAttendeesFromTask(var Attendee: Record Attendee; Task: Record "To-do"; TeamMeetingOrganizer: Code[20])
    var
        Cont: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        SegHeader: Record "Segment Header";
        SegLine: Record "Segment Line";
        Opp: Record Opportunity;
        AttendeeLineNo: Integer;
    begin
        if Task."Segment No." = '' then begin
            if Task.Type = Type::Meeting then
                if Task."Team Code" = '' then begin
                    if Salesperson.Get(Task."Salesperson Code") then
                        Attendee.CreateAttendee(
                          Attendee,
                          Task."No.", 10000, Attendee."Attendance Type"::"To-do Organizer",
                          Attendee."Attendee Type"::Salesperson,
                          Salesperson.Code, true)
                end else
                    Task.CreateAttendeesFromTeam(
                      Attendee,
                      TeamMeetingOrganizer);

            if Attendee.Find('+') then
                AttendeeLineNo := Attendee."Line No." + 10000
            else
                AttendeeLineNo := 10000;

            if Cont.Get(Task."Contact No.") then
                Attendee.CreateAttendee(
                  Attendee,
                  Task."No.", AttendeeLineNo, Attendee."Attendance Type"::Required,
                  Attendee."Attendee Type"::Contact,
                  Cont."No.", Cont."E-Mail" <> '');
        end else begin
            if Task.Type = Type::Meeting then
                if Task."Team Code" = '' then begin
                    if Salesperson.Get(Task."Salesperson Code") then
                        Attendee.CreateAttendee(
                          Attendee,
                          Task."No.", 10000, Attendee."Attendance Type"::"To-do Organizer",
                          Attendee."Attendee Type"::Salesperson,
                          Salesperson.Code, true);
                end else
                    Task.CreateAttendeesFromTeam(Attendee, Task."Team Meeting Organizer");

            if Attendee.Find('+') then
                AttendeeLineNo := Attendee."Line No." + 10000
            else
                AttendeeLineNo := 10000;

            if Opp.Get(Task."Opportunity No.") then
                Attendee.CreateAttendee(
                  Attendee,
                  Task."No.", AttendeeLineNo, Attendee."Attendance Type"::Required,
                  Attendee."Attendee Type"::Contact,
                  Opp."Contact No.",
                  (Cont.Get(Opp."Contact No.") and
                   (Cont."E-Mail" <> '')))
            else
                if SegHeader.Get(Task."Segment No.") then begin
                    SegLine.SetRange("Segment No.", Task."Segment No.");
                    SegLine.SetFilter("Contact No.", '=%1', Task."Contact No.");
                    if SegLine.Find('-') then
                        repeat
                            Attendee.CreateAttendee(
                              Attendee,
                              Task."No.", AttendeeLineNo, Attendee."Attendance Type"::Required,
                              Attendee."Attendee Type"::Contact,
                              SegLine."Contact No.",
                              (Cont.Get(SegLine."Contact No.") and
                               (Cont."E-Mail" <> '')));
                            AttendeeLineNo := AttendeeLineNo + 10000;
                        until SegLine.Next() = 0;
                end;
        end;
    end;

    local procedure CreateTaskInteractLanguages(var TaskInteractLanguage: Record "To-do Interaction Language"; var Attachment: Record Attachment; TaskNo: Code[20])
    var
        TaskInteractLanguage2: Record "To-do Interaction Language";
        Attachment2: Record Attachment;
        MarketingSetup: Record "Marketing Setup";
        AttachmentManagement: Codeunit AttachmentManagement;
        FileName: Text;
    begin
        if TaskInteractLanguage.Find('-') then
            repeat
                TaskInteractLanguage2.Init();
                TaskInteractLanguage2."To-do No." := TaskNo;
                TaskInteractLanguage2."Language Code" := TaskInteractLanguage."Language Code";
                TaskInteractLanguage2.Description := TaskInteractLanguage.Description;
                if TaskInteractLanguage."Attachment No." <> 0 then begin
                    Attachment.Get(TaskInteractLanguage."Attachment No.");
                    Attachment2.Get(AttachmentManagement.InsertAttachment(0));
                    Attachment2.TransferFields(Attachment, false);
                    Attachment.CalcFields("Attachment File");
                    Attachment2."Attachment File" := Attachment."Attachment File";
                    Attachment2.WizSaveAttachment();
                    Attachment2.Modify(true);
                    MarketingSetup.Get();
                    if MarketingSetup."Attachment Storage Type" = MarketingSetup."Attachment Storage Type"::"Disk File" then
                        if Attachment2."No." <> 0 then begin
                            FileName := Attachment2.ConstDiskFileName();
                            if FileName <> '' then
                                Attachment.ExportAttachmentToServerFile(FileName);
                        end;
                    TaskInteractLanguage2."Attachment No." := Attachment2."No.";
                end else
                    TaskInteractLanguage2."Attachment No." := 0;
                TaskInteractLanguage2.Insert();
            until TaskInteractLanguage.Next() = 0;
    end;

    procedure AssignActivityFromTask(var Task: Record "To-do")
    begin
        Init();
        SetFilterFromTask(Task);
        StartWizard2();
    end;

    procedure InsertActivityTask(Task2: Record "To-do"; ActivityCode: Code[10]; var Attendee: Record Attendee)
    var
        ActivityStep: Record "Activity Step";
        TaskDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertActivityTask(Task2, ActivityCode, Attendee, IsHandled);
        if IsHandled then
            exit;

        TaskDate := Task2.Date;
        ActivityStep.SetRange("Activity Code", ActivityCode);
        if ActivityStep.Find('-') then
            repeat
                InsertActivityStepTask(Task2, ActivityStep, TaskDate, Attendee);
            until ActivityStep.Next() = 0
        else
            InsertActivityStepTask(Task2, ActivityStep, TaskDate, Attendee);
    end;

    local procedure InsertActivityStepTask(Task2: Record "To-do"; ActivityStep: Record "Activity Step"; TaskDate: Date; var Attendee2: Record Attendee) TaskNo: Code[20]
    var
        TempTask: Record "To-do" temporary;
        InteractionTemplateSetup: Record "Interaction Template Setup";
        InteractionTemplate: Record "Interaction Template";
        TempTaskInteractionLanguage: Record "To-do Interaction Language" temporary;
        TempAttachment: Record Attachment temporary;
        TempAttendee: Record Attendee temporary;
        TempRMCommentLine: Record "Rlshp. Mgt. Comment Line" temporary;
    begin
        TempTask.Init();
        TempTask := Task2;
        TempTask.Insert();
        CopyFieldsFromActivityStep(TempTask, ActivityStep, TaskDate);

        if TempTask.Type = Type::Meeting then begin
            if not Attendee2.IsEmpty() then begin
                Attendee2.SetRange("Attendance Type", Attendee2."Attendance Type"::"To-do Organizer");
                Attendee2.Find('-')
            end;
            TempAttendee.DeleteAll();
            TempTask.Validate("All Day Event", true);

            InteractionTemplateSetup.Get();
            if (InteractionTemplateSetup."Meeting Invitation" <> '') and
               InteractionTemplate.Get(InteractionTemplateSetup."Meeting Invitation")
            then
                UpdateInteractionTemplate(
                  TempTask, TempTaskInteractionLanguage, TempAttachment, InteractionTemplate.Code, true);

            CreateAttendeesFromTask(TempAttendee, TempTask, Attendee2."Attendee No.");

            TempTask.Validate("Contact No.", '');

            TaskNo := InsertTaskAndRelatedData(
                TempTask, TempTaskInteractionLanguage, TempAttachment, TempAttendee, TempRMCommentLine);
        end else begin
            TempAttendee.DeleteAll();
            CreateAttendeesFromTask(TempAttendee, TempTask, '');

            InsertTaskAndRelatedData(
              TempTask, TempTaskInteractionLanguage, TempAttachment, TempAttendee, TempRMCommentLine);
        end;
        TempTask.Delete();
    end;

    local procedure CopyFieldsFromActivityStep(var TempTask: Record "To-do" temporary; ActivityStep: Record "Activity Step"; TaskDate: Date)
    begin
        if not ActivityStep.IsEmpty() then begin
            TempTask.Type := ActivityStep.Type;
            TempTask.Priority := ActivityStep.Priority;
            TempTask.Description := ActivityStep.Description;
            TempTask.Date := CalcDate(ActivityStep."Date Formula", TaskDate);
        end;
        OnAfterCopyFieldsFromActivityStep(TempTask, ActivityStep);
    end;

    local procedure SetFilterFromTask(var Task: Record "To-do")
    var
        Cont: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Team: Record Team;
        Campaign: Record Campaign;
        Opp: Record Opportunity;
        SegHeader: Record "Segment Header";
    begin
        if Cont.Get(Task.GetFilter("Contact Company No.")) then begin
            Cont.CheckIfPrivacyBlockedGeneric();
            Validate("Contact No.", Cont."No.");
            "Salesperson Code" := Cont."Salesperson Code";
            SetRange("Contact Company No.", "Contact No.");
        end;
        if Cont.Get(Task.GetFilter("Contact No.")) then begin
            Cont.CheckIfPrivacyBlockedGeneric();
            Validate("Contact No.", Cont."No.");
            "Salesperson Code" := Cont."Salesperson Code";
            SetRange("Contact No.", "Contact No.");
        end;
        if Salesperson.Get(Task.GetFilter("Salesperson Code")) then begin
            "Salesperson Code" := Salesperson.Code;
            SetRange("Salesperson Code", "Salesperson Code");
        end;
        if Team.Get(Task.GetFilter("Team Code")) then begin
            Validate("Team Code", Team.Code);
            SetRange("Team Code", "Team Code");
        end;
        if Campaign.Get(Task.GetFilter("Campaign No.")) then begin
            "Campaign No." := Campaign."No.";
            "Salesperson Code" := Campaign."Salesperson Code";
            SetRange("Campaign No.", "Campaign No.");
        end;
        if Opp.Get(Task.GetFilter("Opportunity No.")) then begin
            Validate("Opportunity No.", Opp."No.");
            "Contact No." := Opp."Contact No.";
            "Contact Company No." := Opp."Contact Company No.";
            "Campaign No." := Opp."Campaign No.";
            "Salesperson Code" := Opp."Salesperson Code";
            SetRange("Opportunity No.", "Opportunity No.");
        end;
        if SegHeader.Get(Task.GetFilter("Segment No.")) then begin
            Validate("Segment No.", SegHeader."No.");
            "Campaign No." := SegHeader."Campaign No.";
            "Salesperson Code" := SegHeader."Salesperson Code";
            SetRange("Segment No.", "Segment No.");
        end;

        OnAfterSetFilterFromTask(Rec, Task);
    end;

    procedure CancelOpenTasks(OpportunityNo: Code[20])
    var
        OldTask: Record "To-do";
        OldTask2: Record "To-do";
    begin
        if OpportunityNo = '' then
            exit;

        OldTask.Reset();
        OldTask.SetCurrentKey("Opportunity No.");
        OldTask.SetRange("Opportunity No.", OpportunityNo);
        OldTask.SetRange(Closed, false);
        OldTask.SetRange(Canceled, false);

        if OldTask.Find('-') then
            repeat
                OldTask2.Get(OldTask."No.");
                OldTask2.Recurring := false;
                OldTask2.Validate(Canceled, true);
                OldTask2.Modify();
            until OldTask.Next() = 0;
    end;

    local procedure CreateCommentLines(var RMCommentLine2: Record "Rlshp. Mgt. Comment Line"; TaskNo: Code[20])
    var
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
    begin
        if RMCommentLine2.Find('-') then
            repeat
                RMCommentLine.Init();
                RMCommentLine := RMCommentLine2;
                RMCommentLine."No." := TaskNo;
                RMCommentLine.Insert();
            until RMCommentLine2.Next() = 0;
    end;

    procedure SetDuration(EndingDate: Date; EndingTime: Time)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDuration(Rec, IsHandled, EndingDate, EndingTime);
        if IsHandled then
            exit;

        if (EndingDate < DMY2Date(1, 1, 1900)) or (EndingDate > DMY2Date(31, 12, 2999)) then
            Error(Text006, DMY2Date(1, 1, 1900), DMY2Date(31, 12, 2999));
        if not "All Day Event" then
            Duration := CreateDateTime(EndingDate, EndingTime) - CreateDateTime(Date, "Start Time")
        else
            Duration := CreateDateTime(EndingDate + 1, 0T) - CreateDateTime(Date, 0T);

        Validate(Duration);
    end;

    procedure GetEndDateTime()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetEndDateTime(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if not IsMeetingOrPhoneCall(Rec.Type) or "All Day Event" then
            if "Start Time" <> 0T then
                TempEndDateTime := CreateDateTime(Date - 1, "Start Time") + Duration
            else begin
                TempEndDateTime := CreateDateTime(Date, 0T) + Duration;
                if "All Day Event" then
                    TempEndDateTime := CreateDateTime(DT2Date(TempEndDateTime - 1000), 0T);
            end
        else
            TempEndDateTime := CreateDateTime(Date, "Start Time") + Duration;

        "Ending Date" := DT2Date(TempEndDateTime);
        if "All Day Event" then
            "Ending Time" := 0T
        else
            "Ending Time" := DT2Time(TempEndDateTime);
    end;

    local procedure UpdateAttendeeTasks(OldTaskNo: Code[20])
    var
        Task2: Record "To-do";
        TempTask: Record "To-do" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAttendeeTasks(Rec, IsHandled);
        if IsHandled then
            exit;

        Task2.SetCurrentKey("Organizer To-do No.", "System To-do Type");
        Task2.SetRange("Organizer To-do No.", OldTaskNo);
        if "Team Code" = '' then
            Task2.SetFilter(
              "System To-do Type",
              '%1|%2',
              Task2."System To-do Type"::"Salesperson Attendee",
              Task2."System To-do Type"::"Contact Attendee")
        else
            Task2.SetFilter("System To-do Type", '<>%1', Task2."System To-do Type"::Team);
        if Task2.Find('-') then
            repeat
                TempTask.Init();
                TempTask.TransferFields(Task2, false);
                TempTask.Insert();
                Task2.TransferFields(Rec, false);
                Task2."System To-do Type" := TempTask."System To-do Type";
                if Task2."System To-do Type" = Task2."System To-do Type"::"Contact Attendee" then
                    Task2.Validate("Contact No.", TempTask."Contact No.")
                else
                    Task2."Salesperson Code" := TempTask."Salesperson Code";
                if Task2."No." <> OldTaskNo then
                    Task2.Modify(true);
                TempTask.Delete();
            until Task2.Next() = 0
    end;

    local procedure UpdateInteractionTemplate(var Task: Record "To-do"; var TaskInteractionLanguage: Record "To-do Interaction Language"; var Attachment: Record Attachment; InteractTmplCode: Code[10]; AttachmentTemporary: Boolean)
    var
        InteractTmpl: Record "Interaction Template";
        InteractTemplLanguage: Record "Interaction Tmpl. Language";
        Attachment2: Record Attachment;
        AttachmentManagement: Codeunit AttachmentManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateInteractionTemplate(Task, TaskInteractionLanguage, Attachment, InteractTmplCode, AttachmentTemporary, IsHandled);
        if IsHandled then
            exit;

        Task.Modify();
        TaskInteractionLanguage.SetRange("To-do No.", Task."No.");

        if AttachmentTemporary then
            TaskInteractionLanguage.DeleteAll()
        else
            TaskInteractionLanguage.DeleteAll(true);

        Task."Interaction Template Code" := InteractTmplCode;

        if InteractTmpl.Get(Task."Interaction Template Code") then begin
            Task."Language Code" := InteractTmpl."Language Code (Default)";
            Task.Subject := InteractTmpl.Description;
            Task."Unit Cost (LCY)" := InteractTmpl."Unit Cost (LCY)";
            Task."Unit Duration (Min.)" := InteractTmpl."Unit Duration (Min.)";
            if Task."Campaign No." = '' then
                Task."Campaign No." := InteractTmpl."Campaign No.";

            if AttachmentTemporary then
                Attachment.DeleteAll();

            InteractTemplLanguage.Reset();
            InteractTemplLanguage.SetRange("Interaction Template Code", Task."Interaction Template Code");
            if InteractTemplLanguage.Find('-') then
                repeat
                    TaskInteractionLanguage.Init();
                    TaskInteractionLanguage."To-do No." := Task."No.";
                    TaskInteractionLanguage."Language Code" := InteractTemplLanguage."Language Code";
                    TaskInteractionLanguage.Description := InteractTemplLanguage.Description;
                    if Attachment2.Get(InteractTemplLanguage."Attachment No.") then
                        if AttachmentTemporary then begin
                            Attachment.Init();
                            if Attachment2."Storage Type" = Attachment2."Storage Type"::Embedded then
                                Attachment2.CalcFields("Attachment File");
                            Attachment.TransferFields(Attachment2);
                            Attachment.Insert();
                            TaskInteractionLanguage."Attachment No." := Attachment."No.";
                        end else
                            TaskInteractionLanguage."Attachment No." :=
                              AttachmentManagement.InsertAttachment(InteractTemplLanguage."Attachment No.");
                    TaskInteractionLanguage.Insert();
                until InteractTemplLanguage.Next() = 0
            else
                Task."Attachment No." := 0;
        end else begin
            Task."Language Code" := '';
            Task.Subject := '';
            Task."Unit Cost (LCY)" := 0;
            Task."Unit Duration (Min.)" := 0;
            Task."Attachment No." := 0;
        end;

        if TaskInteractionLanguage.Get(Task."No.", Task."Language Code") then
            Task."Attachment No." := TaskInteractionLanguage."Attachment No.";

        Task.Modify();
    end;

    [Scope('OnPrem')]
    procedure SendMAPIInvitations(Task: Record "To-do"; FromWizard: Boolean)
    var
        Attendee: Record Attendee;
        NoToSend: Integer;
        NoNotSent: Integer;
        Selected: Integer;
        Options: Text[1024];
    begin
        if Task."System To-do Type" <> Task."System To-do Type"::Organizer then
            Task.GetMeetingOrganizerTask(Task);
        if Task."Attachment No." = 0 then begin
            Attendee.SetRange("To-do No.", Task."Organizer To-do No.");
            Attendee.SetRange("Send Invitation", true);
            Attendee.SetRange("Attendee Type", Attendee."Attendee Type"::Contact);
            if not Attendee.IsEmpty() then begin
                Attendee.SetCurrentKey("To-do No.", "Attendance Type");
                Attendee.SetRange("Send Invitation");
                Attendee.SetRange("Attendee Type");
                Attendee.SetRange("Attendance Type", Attendee."Attendance Type"::"To-do Organizer");
                if not Attendee.IsEmpty() then
                    Error(Text067, Task.TableCaption(), Attendee.TableCaption())
            end;
            Attendee.Reset();
        end;

        Attendee.SetRange("To-do No.", Task."Organizer To-do No.");
        Attendee.SetFilter("Attendance Type", '<>%1', Attendee."Attendance Type"::"To-do Organizer");
        Attendee.SetRange("Send Invitation", true);

        if not FromWizard then begin
            NoToSend := Attendee.Count();
            Attendee.SetRange("Invitation Sent", false);
            NoNotSent := Attendee.Count();
            if NoToSend = 0 then
                Error(Text018, Attendee.FieldCaption("Send Invitation"));
            if (NoToSend > NoNotSent) and (NoNotSent <> 0) then begin
                Options :=
                  StrSubstNo(
                    Text019, Attendee.FieldCaption("Send Invitation")) + ',' +
                  Text020 + ',' +
                  Text021;
                Selected := StrMenu(Options, 1);
                if Selected in [0, 3] then
                    Error('');
            end;
            if NoNotSent = 0 then
                if not Confirm(
                     StrSubstNo(
                       Text022, Attendee.FieldCaption("Send Invitation")), false)
                then
                    Error('');

            if NoToSend = NoNotSent then
                if not Confirm(StrSubstNo(Text019, Attendee.FieldCaption("Send Invitation")), false) then
                    Error('');

            Attendee.Reset();
            Attendee.SetRange("To-do No.", Task."Organizer To-do No.");
            Attendee.SetRange("Send Invitation", true);
            if Selected = 2 then
                Attendee.SetRange("Invitation Sent", false);
        end;

        if Attendee.FindFirst() then
            ProcessAttendeeAppointment(Task, Attendee);
    end;

    [Scope('OnPrem')]
    procedure CreateAttachment(PageNotEditable: Boolean)
    var
        TaskInteractionLanguage: Record "To-do Interaction Language";
    begin
        OnBeforeCreateAttachment(Rec, PageNotEditable);

        if "Interaction Template Code" = '' then
            exit;
        if not TaskInteractionLanguage.Get("Organizer To-do No.", "Language Code") then begin
            TaskInteractionLanguage.Init();
            TaskInteractionLanguage."To-do No." := "Organizer To-do No.";
            TaskInteractionLanguage."Language Code" := "Language Code";
            TaskInteractionLanguage.Insert(true);
        end;
        if TaskInteractionLanguage.CreateAttachment(PageNotEditable) then begin
            "Attachment No." := TaskInteractionLanguage."Attachment No.";
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure OpenAttachment(PageNotEditable: Boolean)
    var
        TaskInteractionLanguage: Record "To-do Interaction Language";
    begin
        OnBeforeOpenAttachment(Rec, PageNotEditable);

        if "Interaction Template Code" = '' then
            exit;
        if TaskInteractionLanguage.Get("Organizer To-do No.", "Language Code") then
            if TaskInteractionLanguage."Attachment No." <> 0 then
                TaskInteractionLanguage.OpenAttachment(PageNotEditable);
        Modify(true);
    end;

    [Scope('OnPrem')]
    procedure ImportAttachment()
    var
        TaskInteractionLanguage: Record "To-do Interaction Language";
    begin
        OnBeforeImportAttachment(Rec);

        if "Interaction Template Code" = '' then
            exit;

        if not TaskInteractionLanguage.Get("Organizer To-do No.", "Language Code") then begin
            TaskInteractionLanguage.Init();
            TaskInteractionLanguage."To-do No." := "Organizer To-do No.";
            TaskInteractionLanguage."Language Code" := "Language Code";
            TaskInteractionLanguage.Insert(true);
        end;
        TaskInteractionLanguage.ImportAttachment();
        "Attachment No." := TaskInteractionLanguage."Attachment No.";
        Modify(true);
    end;

    [Scope('OnPrem')]
    procedure ExportAttachment()
    var
        TaskInteractionLanguage: Record "To-do Interaction Language";
    begin
        OnBeforeExportAttachment(Rec);

        if "Interaction Template Code" = '' then
            exit;

        if TaskInteractionLanguage.Get("Organizer To-do No.", "Language Code") then
            if TaskInteractionLanguage."Attachment No." <> 0 then
                TaskInteractionLanguage.ExportAttachment();
    end;

    [Scope('OnPrem')]
    procedure RemoveAttachment(Prompt: Boolean)
    var
        TaskInteractionLanguage: Record "To-do Interaction Language";
    begin
        OnBeforeRemoveAttachment(Rec);

        if "Interaction Template Code" = '' then
            exit;

        if TaskInteractionLanguage.Get("Organizer To-do No.", "Language Code") then
            if TaskInteractionLanguage."Attachment No." <> 0 then
                if TaskInteractionLanguage.RemoveAttachment(Prompt) then begin
                    "Attachment No." := 0;
                    Modify(true);
                end;
        Modify(true);
    end;

    local procedure LogTaskInteraction(var Task: Record "To-do"; var Task2: Record "To-do"; Deliver: Boolean)
    var
        TempSegLine: Record "Segment Line" temporary;
        Cont: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        Attachment: Record Attachment;
        TempAttachment: Record Attachment temporary;
        TempInterLogEntryCommentLine: Record "Inter. Log Entry Comment Line" temporary;
        SegManagement: Codeunit SegManagement;
    begin
        if Attachment.Get(Task."Attachment No.") then begin
            TempAttachment.DeleteAll();
            TempAttachment.Init();
            TempAttachment.WizEmbeddAttachment(Attachment);
            TempAttachment.Insert();
        end;

        TempSegLine.DeleteAll();
        TempSegLine.Init();
        TempSegLine."To-do No." := Task."Organizer To-do No.";
        TempSegLine.SetRange("To-do No.", TempSegLine."To-do No.");
        if Cont.Get(Task2."Contact No.") then
            TempSegLine.Validate("Contact No.", Task2."Contact No.");
        if Salesperson.Get(Task."Salesperson Code") then
            TempSegLine."Salesperson Code" := Salesperson.Code;
        if Campaign.Get(Task."Campaign No.") then
            TempSegLine."Campaign No." := Campaign."No.";
        TempSegLine."Interaction Template Code" := Task."Interaction Template Code";
        TempSegLine."Attachment No." := Task."Attachment No.";
        TempSegLine."Language Code" := Task."Language Code";
        TempSegLine.Subject := Task.Description;
        TempSegLine.Description := Task.Description;
        TempSegLine."Correspondence Type" := TempSegLine."Correspondence Type"::Email;
        TempSegLine."Cost (LCY)" := Task."Unit Cost (LCY)";
        TempSegLine."Duration (Min.)" := Task."Unit Duration (Min.)";
        TempSegLine."Opportunity No." := Task."Opportunity No.";
        TempSegLine.Validate(Date, WorkDate());

        OnLogTaskInteractionOnBeforeTempSegLineInsert(TempSegLine, Task);
        TempSegLine.Insert();
        SegManagement.LogInteraction(TempSegLine, TempAttachment, TempInterLogEntryCommentLine, Deliver, false);
    end;

    procedure CreateAttendeesFromTeam(var Attendee: Record Attendee; TeamMeetingOrganizer: Code[20])
    var
        TeamSalesperson: Record "Team Salesperson";
        AttendeeLineNo: Integer;
    begin
        if TeamMeetingOrganizer = '' then
            exit;
        Attendee.CreateAttendee(
          Attendee,
          "No.", 10000, Attendee."Attendance Type"::"To-do Organizer",
          Attendee."Attendee Type"::Salesperson,
          TeamMeetingOrganizer,
          true);

        TeamSalesperson.SetRange("Team Code", "Team Code");
        if TeamSalesperson.Find('-') then begin
            AttendeeLineNo := 20000;
            repeat
                if TeamSalesperson."Salesperson Code" <> TeamMeetingOrganizer then
                    Attendee.CreateAttendee(
                      Attendee,
                      "No.", AttendeeLineNo, Attendee."Attendance Type"::Required,
                      Attendee."Attendee Type"::Salesperson,
                      TeamSalesperson."Salesperson Code",
                      false);
                AttendeeLineNo := AttendeeLineNo + 10000;
            until TeamSalesperson.Next() = 0;
        end;
    end;

    procedure ChangeTeam()
    var
        Task: Record "To-do";
        TeamSalesperson: Record "Team Salesperson";
        TeamSalespersonOld: Record "Team Salesperson";
        TempAttendee: Record Attendee temporary;
        Attendee: Record Attendee;
        Salesperson: Record "Salesperson/Purchaser";
        AttendeeLineNo: Integer;
        SendInvitation: Boolean;
        TeamCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChangeTeam(Rec, IsHandled);
        if IsHandled then
            exit;

        Modify();
        TeamSalespersonOld.SetRange("Team Code", xRec."Team Code");
        TeamSalesperson.SetRange("Team Code", "Team Code");
        if TeamSalesperson.Find('-') then
            repeat
                TeamSalesperson.Mark(true)
            until TeamSalesperson.Next() = 0;

        if Type = Type::Meeting then begin
            Attendee.SetCurrentKey("To-do No.", "Attendee Type", "Attendee No.");
            Attendee.SetRange("To-do No.", "Organizer To-do No.");
            Attendee.SetRange("Attendee Type", Attendee."Attendee Type"::Salesperson);
            if Attendee.Find('-') then
                repeat
                    TeamSalesperson.SetRange("Salesperson Code", Attendee."Attendee No.");
                    if TeamSalesperson.Find('-') then
                        TeamSalesperson.Mark(false)
                    else
                        if Attendee."Attendance Type" <> Attendee."Attendance Type"::"To-do Organizer" then begin
                            TeamSalespersonOld.SetRange("Salesperson Code", Attendee."Attendee No.");
                            if TeamSalespersonOld.FindFirst() then begin
                                Attendee.Mark(true);
                                DeleteAttendeeTask(Attendee)
                            end
                        end
                until Attendee.Next() = 0;
            Attendee.MarkedOnly(true);
            Attendee.DeleteAll();
        end else begin
            Task.SetCurrentKey("Organizer To-do No.", "System To-do Type");
            Task.SetRange("Organizer To-do No.", "Organizer To-do No.");
            Task.SetFilter("System To-do Type", '%1|%2',
              Task."System To-do Type"::Organizer,
              Task."System To-do Type"::"Salesperson Attendee");
            if Task.Find('-') then
                repeat
                    TeamSalesperson.SetRange("Salesperson Code", Task."Salesperson Code");
                    if TeamSalesperson.Find('-') then
                        TeamSalesperson.Mark(false)
                    else
                        Task.Delete(true)
                until Task.Next() = 0
        end;

        TeamCode := "Team Code";
        Get("No.");
        "Team Code" := TeamCode;

        TeamSalesperson.MarkedOnly(true);
        TeamSalesperson.SetRange("Salesperson Code");
        if TeamSalesperson.Find('-') then
            if Type = Type::Meeting then
                repeat
                    Attendee.Reset();
                    Attendee.SetRange("To-do No.", "Organizer To-do No.");
                    if Attendee.Find('+') then
                        AttendeeLineNo := Attendee."Line No." + 10000
                    else
                        AttendeeLineNo := 10000;
                    if Salesperson.Get(TeamSalesperson."Salesperson Code") then
                        if Salesperson."E-Mail" <> '' then
                            SendInvitation := true
                        else
                            SendInvitation := false;
                    Attendee.CreateAttendee(
                      Attendee,
                      "Organizer To-do No.", AttendeeLineNo,
                      Attendee."Attendance Type"::Required,
                      Attendee."Attendee Type"::Salesperson,
                      TeamSalesperson."Salesperson Code", SendInvitation);
                    CreateSubTask(Attendee, Rec)
                until TeamSalesperson.Next() = 0
            else
                repeat
                    TempAttendee.CreateAttendee(
                      TempAttendee,
                      "No.", 10000,
                      TempAttendee."Attendance Type"::"To-do Organizer",
                      TempAttendee."Attendee Type"::Salesperson,
                      TeamSalesperson."Salesperson Code",
                      true);
                    CreateSubTask(TempAttendee, Rec);
                    TempAttendee.DeleteAll();
                until TeamSalesperson.Next() = 0;
        Modify(true)
    end;

    local procedure ConfirmReassignmentOpenedNotMeetingToDo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmReassignmentOpenedNotMeetingToDo(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if Confirm(StrSubstNo(Text032, "No.", "Salesperson Code")) then
            ReassignTeamTaskToSalesperson()
        else
            "Salesperson Code" := xRec."Salesperson Code"
    end;

    procedure ReassignTeamTaskToSalesperson()
    var
        Task: Record "To-do";
        Attendee: Record Attendee;
        AttendeeLineNo: Integer;
        SalespersonCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReassignTeamTaskToSalesperson(Rec, IsHandled);
        if IsHandled then
            exit;

        Modify();
        if Type = Type::Meeting then begin
            Task.SetCurrentKey("Organizer To-do No.", "System To-do Type");
            Task.SetRange("Organizer To-do No.", "No.");
            Task.SetRange("Salesperson Code", "Salesperson Code");
            if Task.FindFirst() then begin
                Attendee.SetCurrentKey("To-do No.", "Attendee Type", "Attendee No.");
                Attendee.SetRange("To-do No.", "No.");
                Attendee.SetRange("Attendee Type", Attendee."Attendee Type"::Salesperson);
                Attendee.SetRange("Attendee No.", "Salesperson Code");
                if Attendee.FindFirst() then
                    if Attendee."Attendance Type" = Attendee."Attendance Type"::"To-do Organizer" then begin
                        Attendee.Delete();
                        Task.Delete();
                    end else
                        Attendee.Delete(true)
            end;

            SalespersonCode := "Salesperson Code";
            Get("No.");
            "Salesperson Code" := SalespersonCode;

            Task.SetRange("Salesperson Code");
            Task.SetRange("System To-do Type", "System To-do Type"::Organizer);
            if Task.FindFirst() then begin
                Attendee.Reset();
                Attendee.SetCurrentKey("To-do No.", "Attendee Type", "Attendee No.");
                Attendee.SetRange("To-do No.", "No.");
                Attendee.SetRange("Attendee Type", Attendee."Attendee Type"::Salesperson);
                Attendee.SetRange("Attendee No.", Task."Salesperson Code");
                if Attendee.FindFirst() then begin
                    Attendee."Attendance Type" := Attendee."Attendance Type"::Required;
                    Attendee.Modify();
                end;
                Task."System To-do Type" := Task."System To-do Type"::"Salesperson Attendee";
                Task.Modify(true)
            end;

            Attendee.Reset();
            Attendee.SetRange("To-do No.", "No.");
            if Attendee.FindLast() then
                AttendeeLineNo := Attendee."Line No." + 10000
            else
                AttendeeLineNo := 10000;
            Attendee.CreateAttendee(
              Attendee, "No.", AttendeeLineNo,
              Attendee."Attendance Type"::"To-do Organizer",
              Attendee."Attendee Type"::Salesperson,
              "Salesperson Code", true);
            ArrangeOrganizerAttendee();
        end else begin
            Task.SetCurrentKey("Organizer To-do No.", "System To-do Type");
            Task.SetRange("Organizer To-do No.", "No.");
            Task.SetRange("System To-do Type", "System To-do Type"::Organizer);
            if Task.FindFirst() then
                Task.DeleteAll(true);

            if "Contact No." <> '' then begin
                Task.SetRange("System To-do Type", "System To-do Type"::"Contact Attendee");
                if Task.FindFirst() then begin
                    Task."Salesperson Code" := "Salesperson Code";
                    Task.Modify(true)
                end
            end
        end;

        "System To-do Type" := "System To-do Type"::Organizer;
        "Team Code" := '';
        Modify(true);
    end;

    procedure ReassignSalespersonTaskToTeam()
    var
        TeamSalesperson: Record "Team Salesperson";
        Attendee: Record Attendee;
        TempAttendee: Record Attendee temporary;
        Task: Record "To-do";
        AttendeeLineNo: Integer;
        SendInvitation: Boolean;
        SalespersonCode: Code[20];
        TaskNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReassignSalespersonTaskToTeam(Rec, IsHandled);
        if IsHandled then
            exit;

        Modify();
        SalespersonCode := "Salesperson Code";
        "Salesperson Code" := '';
        "System To-do Type" := "System To-do Type"::Team;
        Modify();

        Task.SetCurrentKey("Organizer To-do No.", "System To-do Type");
        Task.SetRange("Organizer To-do No.", "No.");

        if Type = Type::Meeting then begin
            Attendee.SetRange("To-do No.", "No.");
            Attendee.SetRange("Attendance Type", Attendee."Attendance Type"::"To-do Organizer");
            if Attendee.FindFirst() then begin
                Attendee."Attendance Type" := Attendee."Attendance Type"::Required;
                TaskNo := CreateSubTask(Attendee, Rec);
                Attendee."Attendance Type" := Attendee."Attendance Type"::"To-do Organizer";
                Attendee.Modify();
                if Task.Get(TaskNo) then begin
                    Task."System To-do Type" := Task."System To-do Type"::Organizer;
                    Task.Modify();
                end
            end;

            Task.SetFilter("System To-do Type", '<>%1', Task."System To-do Type"::"Contact Attendee");
            TeamSalesperson.SetRange("Team Code", "Team Code");
            if TeamSalesperson.Find('-') then
                repeat
                    Task.SetRange("Salesperson Code", TeamSalesperson."Salesperson Code");
                    if Task.FindFirst() then begin
                        if (Task."System To-do Type" = Task."System To-do Type"::Organizer) and
                           (Task."Salesperson Code" <> SalespersonCode)
                        then begin
                            Task."System To-do Type" := Task."System To-do Type"::"Salesperson Attendee";
                            Modify(true)
                        end
                    end else begin
                        Attendee.Reset();
                        Attendee.SetRange("To-do No.", "No.");
                        if Attendee.FindLast() then
                            AttendeeLineNo := Attendee."Line No." + 10000
                        else
                            AttendeeLineNo := 10000;
                        if Salesperson.Get(TeamSalesperson."Salesperson Code") then
                            if Salesperson."E-Mail" <> '' then
                                SendInvitation := true
                            else
                                SendInvitation := false;
                        Attendee.CreateAttendee(
                          Attendee, "No.", AttendeeLineNo,
                          Attendee."Attendance Type"::Required,
                          Attendee."Attendee Type"::Salesperson,
                          TeamSalesperson."Salesperson Code",
                          SendInvitation);
                        CreateSubTask(Attendee, Rec)
                    end
                until TeamSalesperson.Next() = 0
        end else begin
            TeamSalesperson.SetRange("Team Code", "Team Code");
            if TeamSalesperson.Find('-') then
                repeat
                    TempAttendee.CreateAttendee(
                      TempAttendee,
                      "No.", 10000,
                      TempAttendee."Attendance Type"::"To-do Organizer",
                      TempAttendee."Attendee Type"::Salesperson,
                      TeamSalesperson."Salesperson Code",
                      true);
                    CreateSubTask(TempAttendee, Rec);
                    TempAttendee.DeleteAll();
                until TeamSalesperson.Next() = 0;
        end;

        Modify(true)
    end;

    procedure GetMeetingOrganizerTask(var Task: Record "To-do")
    begin
        if Type = Type::Meeting then
            if "Team Code" <> '' then begin
                Task.SetCurrentKey("Organizer To-do No.", "System To-do Type");
                Task.SetRange("Organizer To-do No.", "Organizer To-do No.");
                Task.SetRange("System To-do Type", "System To-do Type"::Organizer);
                Task.Find('-')
            end else
                Task.Get("Organizer To-do No.")
    end;

    procedure ArrangeOrganizerAttendee()
    var
        Attendee: Record Attendee;
        FirstLineNo: Integer;
        LastLineNo: Integer;
        OrganizerLineNo: Integer;
    begin
        Attendee.SetRange("To-do No.", "No.");
        if not Attendee.FindFirst() then
            exit;
        FirstLineNo := Attendee."Line No.";
        Attendee.FindLast();
        LastLineNo := Attendee."Line No.";

        Attendee.SetCurrentKey("To-do No.", "Attendance Type");
        Attendee.SetRange("Attendance Type", Attendee."Attendance Type"::"To-do Organizer");
        Attendee.FindFirst();
        OrganizerLineNo := Attendee."Line No.";

        if FirstLineNo <> OrganizerLineNo then begin
            Attendee.Rename("No.", LastLineNo + 1);
            Attendee.Get("No.", FirstLineNo);
            Attendee.Rename("No.", OrganizerLineNo);
            Attendee.Get("No.", LastLineNo + 1);
            Attendee.Rename("No.", FirstLineNo)
        end
    end;

    procedure StartWizard()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStartWizard(Rec, IsHandled);
        if IsHandled then
            exit;

        "Wizard Step" := "Wizard Step"::"1";

        "Wizard Contact Name" := GetContactName();
        if Campaign.Get("Campaign No.") then
            "Wizard Campaign Description" := Campaign.Description;
        if Opp.Get("Opportunity No.") then
            "Wizard Opportunity Description" := Opp.Description;
        if SegHeader.Get(GetFilter("Segment No.")) then
            "Segment Description" := SegHeader.Description;
        if Team.Get(GetFilter("Team Code")) then
            "Team To-do" := true;

        Duration := 1440 * 1000 * 60;
        Date := Today;
        OnStartWizardOnAfterSetDate(Rec);
        GetEndDateTime();

        OnStartWizardOnBeforeInsert(Rec);
        Insert();
        OnStartWizardOnAfterInsert(Rec);
        RunCreateTaskPage();
    end;

    local procedure RunCreateTaskPage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCreateTaskPage(Rec, IsHandled);
        if IsHandled then
            exit;

        if PAGE.RunModal(PAGE::"Create Task", Rec) = ACTION::OK then;
    end;

    procedure CheckStatus()
    var
        Salesperson: Record "Salesperson/Purchaser";
    begin
        if Date = 0D then
            ErrorMessage(FieldCaption(Date));

        if Description = '' then
            ErrorMessage(FieldCaption(Description));

        if "Team To-do" and ("Team Code" = '') then
            ErrorMessage(FieldCaption("Team Code"));

        if not "Team To-do" and ("Salesperson Code" = '') then
            ErrorMessage(FieldCaption("Salesperson Code"));

        if Type = Type::Meeting then begin
            if not "All Day Event" then begin
                if "Start Time" = 0T then
                    ErrorMessage(FieldCaption("Start Time"));
                if Duration = 0 then
                    ErrorMessage(FieldCaption(Duration));
            end;

            if ("Interaction Template Code" = '') and "Send on finish" then
                ErrorMessage(FieldCaption("Interaction Template Code"));

            TempAttendee.Reset();
            TempAttendee.SetRange("Attendance Type", TempAttendee."Attendance Type"::"To-do Organizer");
            if TempAttendee.IsEmpty() then begin
                TempAttendee.Reset();
                Error(Text065);
            end;

            if TempAttendee.Find('-') then
                Salesperson.Get(TempAttendee."Attendee No.");
            TempAttendee.Reset();
            if ("Attachment No." = 0) and "Send on finish" then begin
                TempAttendee.SetRange("Send Invitation", true);
                TempAttendee.SetRange("Attendee Type", TempAttendee."Attendee Type"::Contact);
                if not TempAttendee.IsEmpty() then begin
                    TempAttendee.Reset();
                    Error(Text067, TableCaption(), TempAttendee.TableCaption());
                end;
                TempAttendee.Reset();
            end;
            TempAttendee.Reset();
            if "Send on finish" then begin
                TempAttendee.SetRange("Send Invitation", true);
                if TempAttendee.IsEmpty() then begin
                    TempAttendee.Reset();
                    Error(Text068, TempAttendee.FieldCaption("Send Invitation"));
                end;
                TempAttendee.Reset();
            end;
        end;

        if (Location = '') and "Send on finish" then
            ErrorMessage(FieldCaption(Location));
    end;

    procedure FinishWizard(SendExchangeAppointment: Boolean)
    var
        SendOnFinish, IsHandled : Boolean;
    begin
        CreateExchangeAppointment := SendExchangeAppointment;
        if Recurring then begin
            TestField("Recurring Date Interval");
            TestField("Calc. Due Date From");
        end;
        if Type = Type::Meeting then begin
            if not "Team To-do" then begin
                TempAttendee.SetRange("Attendance Type", TempAttendee."Attendance Type"::"To-do Organizer");
                TempAttendee.Find('-');
                Validate("Salesperson Code", TempAttendee."Attendee No.");
                TempAttendee.Reset();
            end;
            IsHandled := false;
            OnFinishWizardOnBeforeContactNoValidation(Rec, IsHandled);
            if not IsHandled then
                Validate("Contact No.", '');
        end else
            CreateAttendeeFromFinishWizard();

        SendOnFinish := "Send on finish";
        "Wizard Step" := "Wizard Step"::" ";
        "Team To-do" := false;
        "Send on finish" := false;
        "Segment Description" := '';
        "Team Meeting Organizer" := '';
        "Activity Code" := '';
        "Wizard Contact Name" := '';
        "Wizard Campaign Description" := '';
        "Wizard Opportunity Description" := '';
        Modify();
        InsertTask(Rec, TempRMCommentLine, TempAttendee, TempTaskInteractionLanguage, TempAttachment, '', SendOnFinish);
        Delete();
    end;

    local procedure CreateAttendeeFromFinishWizard()
    var
        SegLine: Record "Segment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateAttendeeFromFinishWizard(Rec, IsHandled);
        if IsHandled then
            exit;

        if Cont.Get("Contact No.") and (Rec.Type = Rec.Type::Meeting) then
            TempAttendee.CreateAttendee(
              TempAttendee,
              "No.", 10000, TempAttendee."Attendance Type"::Required,
              TempAttendee."Attendee Type"::Contact,
              Cont."No.", Cont."E-Mail" <> '');
        if SegHeader.Get("Segment No.") then begin
            SegLine.SetRange("Segment No.", "Segment No.");
            SegLine.SetFilter("Contact No.", '<>%1', '');
            if SegLine.Find('-') then
                repeat
                    TempAttendee.CreateAttendee(
                      TempAttendee,
                      "No.", SegLine."Line No.", TempAttendee."Attendance Type"::Required,
                      TempAttendee."Attendee Type"::Contact,
                      SegLine."Contact No.",
                      (Cont.Get(SegLine."Contact No.") and
                       (Cont."E-Mail" <> '')));
                until SegLine.Next() = 0;
        end;
    end;

    local procedure GetContactName(): Text[100]
    begin
        if Cont.Get("Contact No.") then
            exit(Cont.Name);
        if Cont.Get("Contact Company No.") then
            exit(Cont.Name);
    end;

    local procedure ErrorMessage(FieldName: Text[1024])
    begin
        Error(Text043, FieldName);
    end;

    procedure AssignDefaultAttendeeInfo()
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionTemplateSetup: Record "Interaction Template Setup";
        SegLine: Record "Segment Line";
        TeamSalesperson: Record "Team Salesperson";
        Salesperson: Record "Salesperson/Purchaser";
        AttendeeLineNo: Integer;
    begin
        if TempAttendee.Find('+') then
            AttendeeLineNo := TempAttendee."Line No." + 10000
        else
            AttendeeLineNo := 10000;
        case true of
            (GetFilter("Contact No.") <> '') and (GetFilter("Salesperson Code") <> ''):
                begin
                    if Salesperson.Get(GetFilter("Salesperson Code")) then begin
                        TempAttendee.CreateAttendee(
                          TempAttendee,
                          "No.", AttendeeLineNo,
                          TempAttendee."Attendance Type"::"To-do Organizer",
                          TempAttendee."Attendee Type"::Salesperson,
                          Salesperson.Code, true);
                        AttendeeLineNo += 10000;
                    end;
                    if Cont.Get(GetFilter("Contact No.")) then begin
                        TempAttendee.CreateAttendee(
                          TempAttendee,
                          "No.", AttendeeLineNo,
                          TempAttendee."Attendance Type"::Required,
                          TempAttendee."Attendee Type"::Contact,
                          Cont."No.",
                          Cont."E-Mail" <> '');
                        AttendeeLineNo += 10000;
                    end;
                end;
            (GetFilter("Contact No.") <> '') and (GetFilter("Campaign No.") <> ''):
                begin
                    if Campaign.Get(GetFilter("Campaign No.")) then
                        if Salesperson.Get(Campaign."Salesperson Code") then begin
                            TempAttendee.CreateAttendee(
                              TempAttendee,
                              "No.", AttendeeLineNo,
                              TempAttendee."Attendance Type"::"To-do Organizer",
                              TempAttendee."Attendee Type"::Salesperson,
                              Salesperson.Code, true);
                            AttendeeLineNo += 10000
                        end;
                    if Cont.Get(GetFilter("Contact No.")) then begin
                        TempAttendee.CreateAttendee(
                          TempAttendee,
                          "No.", AttendeeLineNo,
                          TempAttendee."Attendance Type"::Required,
                          TempAttendee."Attendee Type"::Contact,
                          Cont."No.", Cont."E-Mail" <> '');
                        AttendeeLineNo += 10000;
                    end;
                end
            else begin
                if Cont.Get(GetFilter("Contact No.")) then begin
                    if Cont."Salesperson Code" <> '' then begin
                        TempAttendee.CreateAttendee(
                          TempAttendee,
                          "No.", AttendeeLineNo,
                          TempAttendee."Attendance Type"::"To-do Organizer",
                          TempAttendee."Attendee Type"::Salesperson,
                          Cont."Salesperson Code", true);
                        AttendeeLineNo += 10000
                    end;
                    TempAttendee.CreateAttendee(
                      TempAttendee,
                      "No.", AttendeeLineNo,
                      TempAttendee."Attendance Type"::Required,
                      TempAttendee."Attendee Type"::Contact,
                      Cont."No.", Cont."E-Mail" <> '');
                    AttendeeLineNo += 10000;
                end else
                    if Cont.Get(GetFilter("Contact Company No.")) then begin
                        if Cont."Salesperson Code" <> '' then begin
                            TempAttendee.CreateAttendee(
                              TempAttendee,
                              "No.", AttendeeLineNo,
                              TempAttendee."Attendance Type"::"To-do Organizer",
                              TempAttendee."Attendee Type"::Salesperson,
                              Cont."Salesperson Code", true);
                            AttendeeLineNo += 10000
                        end;
                        TempAttendee.CreateAttendee(
                          TempAttendee,
                          "No.", AttendeeLineNo,
                          TempAttendee."Attendance Type"::Required,
                          TempAttendee."Attendee Type"::Contact,
                          Cont."No.", Cont."E-Mail" <> '');
                        AttendeeLineNo += 10000;
                    end;

                if Salesperson.Get(GetFilter("Salesperson Code")) then begin
                    TempAttendee.CreateAttendee(
                      TempAttendee,
                      "No.", AttendeeLineNo,
                      TempAttendee."Attendance Type"::"To-do Organizer",
                      TempAttendee."Attendee Type"::Salesperson,
                      Salesperson.Code, true);
                    AttendeeLineNo += 10000;
                end;

                if Campaign.Get(GetFilter("Campaign No.")) then
                    if Salesperson.Get(Campaign."Salesperson Code") then begin
                        TempAttendee.CreateAttendee(
                          TempAttendee,
                          "No.", AttendeeLineNo,
                          TempAttendee."Attendance Type"::"To-do Organizer",
                          TempAttendee."Attendee Type"::Salesperson,
                          Salesperson.Code, true);
                        AttendeeLineNo += 10000
                    end;

                if Opp.Get(GetFilter("Opportunity No.")) then begin
                    if Salesperson.Get(Opp."Salesperson Code") then begin
                        TempAttendee.CreateAttendee(
                          TempAttendee,
                          "No.", AttendeeLineNo,
                          TempAttendee."Attendance Type"::"To-do Organizer",
                          TempAttendee."Attendee Type"::Salesperson,
                          Salesperson.Code, true);
                        AttendeeLineNo += 10000
                    end;
                    if Cont.Get(Opp."Contact No.") then begin
                        TempAttendee.CreateAttendee(
                          TempAttendee,
                          "No.", AttendeeLineNo,
                          TempAttendee."Attendance Type"::Required,
                          TempAttendee."Attendee Type"::Contact,
                          Cont."No.", Cont."E-Mail" <> '');
                        AttendeeLineNo += 10000
                    end;
                end;
            end;
        end;

        if SegHeader.Get(GetFilter("Segment No.")) then begin
            if Salesperson.Get(SegHeader."Salesperson Code") then begin
                TempAttendee.CreateAttendee(
                  TempAttendee,
                  "No.", AttendeeLineNo,
                  TempAttendee."Attendance Type"::"To-do Organizer",
                  TempAttendee."Attendee Type"::Salesperson,
                  Salesperson.Code, true);
                AttendeeLineNo += 10000
            end;
            SegLine.SetRange("Segment No.", "Segment No.");
            SegLine.SetFilter("Contact No.", '<>%1', '');
            if SegLine.Find('-') then
                repeat
                    TempAttendee.CreateAttendee(
                      TempAttendee,
                      "No.", AttendeeLineNo,
                      TempAttendee."Attendance Type"::Required,
                      TempAttendee."Attendee Type"::Contact,
                      SegLine."Contact No.",
                      (Cont.Get(SegLine."Contact No.") and
                       (Cont."E-Mail" <> '')));
                    AttendeeLineNo += 10000
                until SegLine.Next() = 0;
        end;
        if Team.Get("Team Code") then begin
            TeamSalesperson.SetRange("Team Code", Team.Code);
            if TeamSalesperson.Find('-') then
                repeat
                    TempAttendee.SetRange("Attendee Type", TempAttendee."Attendee Type"::Salesperson);
                    TempAttendee.SetRange("Attendee No.", TeamSalesperson."Salesperson Code");
                    if not TempAttendee.Find('-') then
                        if Salesperson.Get(TeamSalesperson."Salesperson Code") then begin
                            TempAttendee.Reset();
                            TempAttendee.CreateAttendee(
                              TempAttendee,
                              "No.", AttendeeLineNo,
                              TempAttendee."Attendance Type"::Required,
                              TempAttendee."Attendee Type"::Salesperson,
                              TeamSalesperson."Salesperson Code",
                              Salesperson."E-Mail" <> '');
                            AttendeeLineNo += 10000
                        end;
                    TempAttendee.Reset();
                until TeamSalesperson.Next() = 0;
        end;

        InteractionTemplateSetup.Get();
        if (InteractionTemplateSetup."Meeting Invitation" <> '') and
           InteractionTemplate.Get(InteractionTemplateSetup."Meeting Invitation")
        then
            UpdateInteractionTemplate(
              Rec, TempTaskInteractionLanguage, TempAttachment, InteractionTemplate.Code, true);

        OnAfterAssignDefaultAttendeeInfo(Rec, AttendeeLineNo, TempAttendee);
    end;

    [Scope('OnPrem')]
    procedure ValidateInteractionTemplCode()
    begin
        UpdateInteractionTemplate(
          Rec, TempTaskInteractionLanguage, TempAttachment, "Interaction Template Code", true);
        LoadTempAttachment();
    end;

    [Scope('OnPrem')]
    procedure AssistEditAttachment()
    begin
        if TempAttachment.Get("Attachment No.") then begin
            TempAttachment.OpenAttachment("Interaction Template Code" + ' ' + Description, true, "Language Code");
            TempAttachment.Modify();
        end else
            Error(Text047);
    end;

    procedure ValidateLanguageCode()
    begin
        if "Language Code" = xRec."Language Code" then
            exit;

        if not TempTaskInteractionLanguage.Get("No.", "Language Code") then begin
            if "No." = '' then
                Error(Text009, TempTaskInteractionLanguage.TableCaption());
        end else
            "Attachment No." := TempTaskInteractionLanguage."Attachment No.";
    end;

    procedure LookupLanguageCode()
    begin
        TempTaskInteractionLanguage.SetFilter("To-do No.", '');
        if TempTaskInteractionLanguage.Get('', "Language Code") then
            if PAGE.RunModal(0, TempTaskInteractionLanguage) = ACTION::LookupOK then begin
                "Language Code" := TempTaskInteractionLanguage."Language Code";
                "Attachment No." := TempTaskInteractionLanguage."Attachment No.";
            end;
    end;

    procedure LoadTempAttachment()
    var
        Attachment: Record Attachment;
        TempAttachment2: Record Attachment temporary;
    begin
        if TempAttachment.FindSet() then
            repeat
                TempAttachment2 := TempAttachment;
                TempAttachment2.Insert();
            until TempAttachment.Next() = 0;

        if TempAttachment2.FindSet() then
            repeat
                Attachment.Get(TempAttachment2."No.");
                Attachment.CalcFields("Attachment File");
                TempAttachment.Get(TempAttachment2."No.");
                TempAttachment.WizEmbeddAttachment(Attachment);
                TempAttachment."No." := TempAttachment2."No.";
                TempAttachment.Modify();
            until TempAttachment2.Next() = 0;
    end;

    procedure ClearDefaultAttendeeInfo()
    begin
        TempAttendee.DeleteAll();
        TempAttachment.DeleteAll();
        TempTaskInteractionLanguage.DeleteAll();
        "Interaction Template Code" := '';
        "Language Code" := '';
        "Attachment No." := 0;
        Subject := '';
        "Unit Cost (LCY)" := 0;
        "Unit Duration (Min.)" := 0;
        Modify();
    end;

    procedure GetAttendee(var Attendee: Record Attendee)
    begin
        Attendee.DeleteAll();
        if TempAttendee.Find('-') then
            repeat
                Attendee := TempAttendee;
                Attendee.Insert();
            until TempAttendee.Next() = 0;
    end;

    procedure SetAttendee(var Attendee: Record Attendee)
    begin
        TempAttendee.DeleteAll();

        if Attendee.FindSet() then
            repeat
                TempAttendee := Attendee;
                TempAttendee.Insert();
            until Attendee.Next() = 0;
    end;

    procedure SetComments(var RMCommentLine: Record "Rlshp. Mgt. Comment Line")
    begin
        TempRMCommentLine.DeleteAll();
        if RMCommentLine.FindSet() then
            repeat
                TempRMCommentLine := RMCommentLine;
                TempRMCommentLine.Insert();
            until RMCommentLine.Next() = 0;
    end;

    local procedure StartWizard2()
    begin
        "Wizard Contact Name" := GetContactName();
        if Cont.Get(GetFilter("Contact No.")) then
            "Wizard Contact Name" := Cont.Name
        else
            if Cont.Get(GetFilter("Contact Company No.")) then
                "Wizard Contact Name" := Cont.Name;

        if Campaign.Get(GetFilter("Campaign No.")) then
            "Wizard Campaign Description" := Campaign.Description;

        if SegHeader.Get(GetFilter("Segment No.")) then
            "Segment Description" := SegHeader.Description;

        "Wizard Step" := "Wizard Step"::"1";
        Duration := 1440 * 1000 * 60;

        OnStartWizard2OnBeforeInsert(Rec);
        Insert();

        if PAGE.RunModal(PAGE::"Assign Activity", Rec) = ACTION::OK then;
    end;

    procedure CheckAssignActivityStatus()
    begin
        if "Activity Code" = '' then
            ErrorMessage(Text051);
        if Date = 0D then
            ErrorMessage(FieldCaption(Date));
        if ("Team Code" = '') and ("Salesperson Code" = '') then
            Error(Text053, FieldCaption("Salesperson Code"), FieldCaption("Team Code"));
        if ("Team Code" <> '') and
           Activity.IncludesMeeting("Activity Code") and
           ("Team Meeting Organizer" = '')
        then
            Error(Text056, "Activity Code");
    end;

    [Scope('OnPrem')]
    procedure FinishAssignActivity()
    var
        TempRMCommentLine: Record "Rlshp. Mgt. Comment Line" temporary;
        TempAttendee: Record Attendee temporary;
        TempTaskInteractionLanguage: Record "To-do Interaction Language" temporary;
        TempAttachment: Record Attachment temporary;
    begin
        TempAttendee.DeleteAll();
        if "Team Meeting Organizer" <> '' then
            TempAttendee.CreateAttendee(
              TempAttendee,
              "No.", 10000, TempAttendee."Attendance Type"::"To-do Organizer",
              TempAttendee."Attendee Type"::Salesperson,
              "Team Meeting Organizer",
              true)
        else
            if "Salesperson Code" <> '' then
                TempAttendee.CreateAttendee(
                  TempAttendee,
                  "No.", 10000, TempAttendee."Attendance Type"::"To-do Organizer",
                  TempAttendee."Attendee Type"::Salesperson,
                  "Salesperson Code",
                  true);
        InsertTask(
          Rec, TempRMCommentLine, TempAttendee,
          TempTaskInteractionLanguage, TempAttachment, "Activity Code", false);
        Delete();
    end;

    local procedure FillSalesPersonContact(var TaskParameter: Record "To-do"; AttendeeParameter: Record Attendee)
    begin
        case AttendeeParameter."Attendee Type" of
            AttendeeParameter."Attendee Type"::Contact:
                TaskParameter.Validate("Contact No.", AttendeeParameter."Attendee No.");
            AttendeeParameter."Attendee Type"::Salesperson:
                TaskParameter.Validate("Salesperson Code", AttendeeParameter."Attendee No.");
        end;
    end;

    procedure SetRunFromForm()
    begin
        RunFormCode := true;
    end;

    procedure IsCalledFromForm(): Boolean
    begin
        exit((CurrFieldNo <> 0) or RunFormCode);
    end;

    local procedure OneDayDuration(): Integer
    begin
        exit(86400000); // 24 * 60 * 60 * 1000 = 86,400,000 ms in 24 hours
    end;

    local procedure GetCurrentUserTimeZone(var TimeZoneInfo: DotNet TimeZoneInfo; TimeZoneID: Text)
    var
        TimeZoneInfoRussianStandard: DotNet TimeZoneInfo;
    begin
        if TimeZoneID = 'Russian Standard Time' then begin
            TimeZoneInfoRussianStandard := TimeZoneInfoRussianStandard.FindSystemTimeZoneById(TimeZoneID);
            TimeZoneInfo := TimeZoneInfo.CreateCustomTimeZone(TimeZoneID, TimeZoneInfoRussianStandard.BaseUtcOffset, '', '');
        end else
            TimeZoneInfo := TimeZoneInfo.FindSystemTimeZoneById(TimeZoneID);
    end;

    local procedure InitializeExchangeAppointment(var Appointment: DotNet IAppointment; var ExchangeWebServicesServer: Codeunit "Exchange Web Services Server")
    var
        TimeZoneInfo: DotNet TimeZoneInfo;
    begin
        SetupExchangeService(ExchangeWebServicesServer);
        ExchangeWebServicesServer.CreateAppointment(Appointment);
        GetCurrentUserTimeZone(TimeZoneInfo, ExchangeWebServicesServer.GetCurrentUserTimeZone());
        UpdateAppointment(Appointment, TimeZoneInfo);
    end;

    local procedure UpdateAppointmentSalesPersonList(var SalesPersonList: Text; AddSalesPersonName: Text[50])
    begin
        if AddSalesPersonName <> '' then
            if SalesPersonList = '' then
                SalesPersonList := AddSalesPersonName
            else
                SalesPersonList += ', ' + AddSalesPersonName;
    end;

    local procedure SaveAppointment(var Appointment: DotNet IAppointment)
    begin
        Appointment.SendAppointment();
    end;

    [Scope('OnPrem')]
    procedure UpdateAppointment(var Appointment: DotNet IAppointment; TimeZoneInfo: DotNet TimeZoneInfo)
    var
        DateTime: DateTime;
    begin
        Appointment.Subject := Description;
        Appointment.Location := Location;
        DateTime := CreateDateTime(Date, "Start Time");
        Appointment.MeetingStart := DateTime;
        if "All Day Event" then
            Appointment.IsAllDayEvent := true
        else begin
            DateTime := CreateDateTime("Ending Date", "Ending Time");
            Appointment.MeetingEnd := DateTime;
        end;
        Appointment.StartTimeZone := TimeZoneInfo;
        Appointment.EndTimeZone := TimeZoneInfo;
    end;

    [Scope('OnPrem')]
    procedure SetupExchangeService(var ExchangeWebServicesServer: Codeunit "Exchange Web Services Server")
    var
        User: Record User;
    begin
        Commit();
        User.SetRange("User Name", UserId);
        if not User.FindFirst() and not Initialize(ExchangeWebServicesServer, User."Authentication Email") then
            Error('');
    end;

    local procedure MakeAppointmentBody(Task: Record "To-do"; SalespeopleList: Text; SalespersonName: Text[50]): Text
    begin
        exit(
          StrSubstNo(Text015, SalespeopleList) + '<br/><br/>' +
          StrSubstNo(Text016, Format(Task.Date), Format(Task."Start Time"), Format(Task.Location)) + '<br/><br/>' +
          Text017 + '<br/>' +
          SalespersonName + '<br/>' +
          Format(Today) + ' ' + Format(Time));
    end;

    local procedure SetAttendeeInvitationSent(var Attendee: Record Attendee)
    begin
        Attendee."Invitation Sent" := true;
        Attendee.Modify();
    end;

    [Scope('OnPrem')]
    procedure AddAppointmentAttendee(var Appointment: DotNet IAppointment; var Attendee: Record Attendee; Email: Text)
    begin
        if Attendee."Attendance Type" = Attendee."Attendance Type"::Required then
            Appointment.AddRequiredAttendee(Email)
        else
            Appointment.AddOptionalAttendee(Email);
        SetAttendeeInvitationSent(Attendee);
    end;

    local procedure ProcessAttendeeAppointment(Task: Record "To-do"; var Attendee: Record Attendee)
    var
        Task2: Record "To-do";
        Salesperson: Record "Salesperson/Purchaser";
        Salesperson2: Record "Salesperson/Purchaser";
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
        Mail: Codeunit Mail;
        Appointment: DotNet IAppointment;
        SalesPersonList: Text;
        Body: Text;
    begin
        if CreateExchangeAppointment then
            InitializeExchangeAppointment(Appointment, ExchangeWebServicesServer);
        repeat
            if FindAttendeeTask(Task2, Attendee) then
                if Attendee."Attendee Type" = Attendee."Attendee Type"::Salesperson then
                    if Salesperson2.Get(Task2."Salesperson Code") and
                       Salesperson.Get(Task."Salesperson Code")
                    then
                        if CreateExchangeAppointment then begin
                            UpdateAppointmentSalesPersonList(SalesPersonList, Salesperson2.Name);
                            if Salesperson2."E-Mail" <> '' then
                                AddAppointmentAttendee(Appointment, Attendee, Salesperson2."E-Mail");
                        end else begin
                            Body := MakeAppointmentBody(Task, Salesperson2.Name, Salesperson.Name);
                            if Mail.NewMessage(Salesperson2."E-Mail", '', '', Task2.Description, Body, '', false) then
                                SetAttendeeInvitationSent(Attendee)
                            else
                                Message(Text023, Attendee."Attendee Name");
                        end
                    else begin
                        LogTaskInteraction(Task, Task2, true);
                        SetAttendeeInvitationSent(Attendee);
                    end;
        until Attendee.Next() = 0;
        if CreateExchangeAppointment and (SalesPersonList <> '') then begin
            Body := MakeAppointmentBody(Task, SalesPersonList, Salesperson.Name);
            Appointment.Body := Body;
            SaveAppointment(Appointment)
        end;
    end;

    [TryFunction]
    local procedure Initialize(var ExchangeWebServicesServer: Codeunit "Exchange Web Services Server"; AuthenticationEmail: Text[250])
    var
        ExchangeServiceSetup: Record "Exchange Service Setup";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        AccessToken: SecretText;
    begin
        AccessToken := AzureADMgt.GetAccessTokenAsSecretText(AzureADMgt.GetO365Resource(), AzureADMgt.GetO365ResourceName(), false);

        if not AccessToken.IsEmpty() then begin
            ExchangeWebServicesServer.InitializeWithOAuthToken(AccessToken, ExchangeWebServicesServer.GetEndpoint());
            exit;
        end;

        ExchangeServiceSetup.Get();

        ExchangeWebServicesServer.InitializeWithCertificate(
          ExchangeServiceSetup."Azure AD App. ID", ExchangeServiceSetup."Azure AD App. Cert. Thumbprint",
          ExchangeServiceSetup."Azure AD Auth. Endpoint", ExchangeServiceSetup."Exchange Service Endpoint",
          ExchangeServiceSetup."Exchange Resource Uri");

        ExchangeWebServicesServer.SetImpersonatedIdentity(AuthenticationEmail);
    end;

    local procedure IsMeetingOrPhoneCall(TaskType: Enum "Task Type"): Boolean
    begin
        exit(TaskType in [TaskType::Meeting, TaskType::"Phone Call"]);
    end;

    local procedure CreateAttendeesSubTask(var Attendee: Record Attendee; ToDo: Record "To-do")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSubTaskForAttendees(ToDo, IsHandled);
        if IsHandled then
            exit;

        if Attendee.Find('-') then
            repeat
                CreateSubTask(Attendee, ToDo);
            until Attendee.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsFromActivityStep(var TempTask: Record "To-do" temporary; ActivityStep: Record "Activity Step")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterFromTask(var ToTask: Record "To-do"; var FromTask: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTask(var Todo: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeTeam(var Task: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmReassignmentOpenedNotMeetingToDo(var ToTask: Record "To-do"; var IsHandled: Boolean; xToTask: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAttendeeFromFinishWizard(var ToTask: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSubTask(Attendee: Record Attendee; Task: Record "To-do"; var TaskNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEndDateTime(var ToTask: Record "To-do"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTaskAndRelatedData(var Task: Record "To-do"; var SkipTypeUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReassignSalespersonTaskToTeam(var Task: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReassignTeamTaskToSalesperson(var Task: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCreateTaskPage(var Task: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDuration(var Task: Record "To-do"; var IsHandled: Boolean; EndingDate: Date; EndingTime: Time)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartWizard(var Todo: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTaskFromTaskOnBeforeStartWizard(var Task: Record "To-do"; var FromTask: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTaskFromSalesHeaderOnBeforeStartWizard(var Task: Record "To-do"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTaskFromSalesHeaderoOnBeforeStartWizard(var Task: Record "To-do"; SalesHeader: Record "Sales Header")
    begin
        // Obsolete
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTaskFromInteractLogEntryOnBeforeStartWizard(var Task: Record "To-do"; InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionOnBeforeCreatePhoneCall(var SegLine: Record "Segment Line"; var Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAttendeeTasks(var Task: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTeamCode(var Task: Record "To-do"; xTask: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSalespersonCode(var Task: Record "To-do"; xTask: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateContactNo(var Task: Record "To-do"; xTask: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateType(var Task: Record "To-do"; xTask: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteAttendeeTask(var Task: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogTaskInteractionOnBeforeTempSegLineInsert(var SegmentLine: Record "Segment Line"; Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStartWizardOnAfterSetDate(var Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStartWizardOnBeforeInsert(var Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTaskAndRelatedData(var Task2: Record "To-do"; TaskNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCompletedBy(var Task: Record "To-do"; xTask: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStartWizard2OnBeforeInsert(var Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOrganizerTask(Task: Record "To-do"; var TempAttendee: Record Attendee temporary; TaskNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishWizardOnBeforeContactNoValidation(var ToDo: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSubTaskForAttendees(var ToDo: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateInteraction(var Todo: Record "To-do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateInteractionTemplate(var Todo: Record "To-do"; var TodoInteractionLanguage: Record "To-do Interaction Language"; var Attachment: Record Attachment; InteractTmplCode: Code[10]; AttachmentTemporary: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAttachment(var Todo: Record "To-do"; var PageNotEditable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenAttachment(var Todo: Record "To-do"; var PageNotEditable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImportAttachment(var Todo: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportAttachment(var Todo: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRemoveAttachment(var Todo: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStartWizardOnAfterInsert(var Todo: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertActivityTask(var Task: Record "To-Do"; ActivityCode: Code[10]; var Attendee: Record Attendee; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateClosed(var Todo: Record "To-do"; xTodo: Record "To-do"; var SkipConfirmDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignDefaultAttendeeInfo(var Todo: Record "To-do"; var AttendeeLineNo: Integer; var TempAttendee: Record Attendee temporary)
    begin
    end;
}