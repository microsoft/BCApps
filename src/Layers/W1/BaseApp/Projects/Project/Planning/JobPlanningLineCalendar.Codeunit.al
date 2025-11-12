// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using System;
using System.Email;
using System.Security.AccessControl;
using System.Utilities;

codeunit 1034 "Job Planning Line - Calendar"
{
    TableNo = "Job Planning Line";

    trigger OnRun()
    var
        LocalJobPlanningLine: Record "Job Planning Line";
    begin
        LocalJobPlanningLine.SetRange("Job No.", Rec."Job No.");
        LocalJobPlanningLine.SetRange("Job Task No.", Rec."Job Task No.");
        LocalJobPlanningLine.SetFilter("Line Type", '%1|%2', Rec."Line Type"::Budget, Rec."Line Type"::"Both Budget and Billable");
        LocalJobPlanningLine.SetRange(Type, Rec.Type::Resource);
        LocalJobPlanningLine.SetFilter("No.", '<>''''');
        if LocalJobPlanningLine.FindSet() then
            repeat
                SetPlanningLine(LocalJobPlanningLine);
                CreateAndSend();
            until LocalJobPlanningLine.Next() = 0
        else
            Message(NoPlanningLinesMsg);
    end;

    var
        JobPlanningLineCalendar: Record "Job Planning Line - Calendar";
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        Contact: Record Contact;
        Customer: Record Customer;
        ProjectManagerResource: Record Resource;
        Resource: Record Resource;

        AdditionalResourcesTxt: Label 'Additional Resources';
        SetPlanningLineErr: Label 'You must specify a project planning line before you can send the appointment.';
        DateTimeFormatTxt: Label '<Year4><Month,2><Day,2>T<Hours24,2><Minutes,2><Seconds,2>', Locked = true;
        ProdIDTxt: Label '//Microsoft Corporation//Dynamics 365//EN', Locked = true;
        NoPlanningLinesMsg: Label 'There are no applicable planning lines for this action.';
        SendToCalendarTelemetryTxt: Label 'Sending project planning line to calendar.', Locked = true;

    procedure SetPlanningLine(NewJobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine := NewJobPlanningLine;
        UpdateJob();
        UpdateJobTask();
        UpdateResource();

        OnAfterSetPlanningLine(NewJobPlanningLine, ProjectManagerResource);
    end;

    [Scope('OnPrem')]
    procedure CreateAndSend()
    var
        TempEmailItem: Record "Email Item" temporary;
        OfficeMgt: Codeunit "Office Management";
    begin
        if JobPlanningLine."No." = '' then
            Error(SetPlanningLineErr);

        if JobPlanningLineCalendar.ShouldSendCancellation(JobPlanningLine) then
            if CreateCancellation(TempEmailItem) then
                TempEmailItem.Send(true, Enum::"Email Scenario"::"Job Planning Line Calendar");

        if JobPlanningLineCalendar.ShouldSendRequest(JobPlanningLine) then
            if CreateRequest(TempEmailItem) then begin
                Session.LogMessage('0000ACX', SendToCalendarTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeMgt.GetOfficeAddinTelemetryCategory());
                TempEmailItem.Send(true, Enum::"Email Scenario"::"Job Planning Line Calendar");
            end;
    end;

    [Scope('OnPrem')]
    procedure CreateRequest(var TempEmailItem: Record "Email Item" temporary): Boolean
    var
        Email: Text[80];
    begin
        if JobPlanningLine."No." = '' then
            Error(SetPlanningLineErr);

        Email := GetResourceEmail(JobPlanningLine."No.");

        if Email <> '' then begin
            JobPlanningLineCalendar.InsertOrUpdate(JobPlanningLine);
            GenerateEmail(TempEmailItem, Email, false);
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateCancellation(var TempEmailItem: Record "Email Item" temporary): Boolean
    var
        Email: Text[80];
    begin
        if JobPlanningLine."No." = '' then
            Error(SetPlanningLineErr);

        if not JobPlanningLineCalendar.HasBeenSent(JobPlanningLine) then
            exit(false);

        Email := GetResourceEmail(JobPlanningLineCalendar."Resource No.");
        if Email <> '' then begin
            GenerateEmail(TempEmailItem, Email, true);
            JobPlanningLineCalendar.Delete();
            exit(true);
        end;
    end;

    local procedure GenerateEmail(var TempEmailItem: Record "Email Item" temporary; RecipientEmail: Text[80]; Cancel: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        Stream: OutStream;
        InStream: Instream;
        ICS: Text;
    begin
        ICS := GenerateICS(Cancel);
        TempBlob.CreateOutStream(Stream, TextEncoding::UTF8);
        Stream.Write(ICS);
        TempBlob.CreateInStream(InStream);

        TempEmailItem.Initialize();
        TempEmailItem.Subject := JobTask.Description;
        TempEmailItem.AddAttachment(InStream, StrSubstNo('%1.ics', JobTask.TableCaption()));
        TempEmailItem."Send to" := RecipientEmail;
    end;

    local procedure GenerateICS(Cancel: Boolean) ICS: Text
    var
        StringBuilder: DotNet StringBuilder;
        Location: Text;
        Summary: Text;
        Status: Text;
        Method: Text;
        Description: Text;
    begin
        Location := StrSubstNo('%1, %2, %3', Customer.Address, Customer.City, Customer."Country/Region Code");
        Summary := StrSubstNo('%1:%2:%3', JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");

        if Cancel then begin
            Method := 'CANCEL';
            Status := 'CANCELLED';
        end else begin
            Method := 'REQUEST';
            Status := 'CONFIRMED';
        end;
        Description := GetDescription();

        StringBuilder := StringBuilder.StringBuilder();
        StringBuilder.AppendLine('BEGIN:VCALENDAR');
        StringBuilder.AppendLine('VERSION:2.0');
        StringBuilder.AppendLine('PRODID:-' + ProdIDTxt);
        StringBuilder.AppendLine('METHOD:' + Method);
        StringBuilder.AppendLine('BEGIN:VEVENT');
        StringBuilder.AppendLine('UID:' + DelChr(JobPlanningLineCalendar.UID, '<>', '{}'));
        StringBuilder.AppendLine('ORGANIZER:' + GetOrganizer());
        StringBuilder.AppendLine('LOCATION:' + Location);
        StringBuilder.AppendLine('DTSTART:' + GetStartDate());
        StringBuilder.AppendLine('DTEND:' + GetEndDate());
        StringBuilder.AppendLine('SUMMARY:' + Summary);
        StringBuilder.AppendLine('DESCRIPTION:' + Description);
        StringBuilder.AppendLine('X-ALT-DESC;FMTTYPE=' + GetHtmlDescription(Description));
        StringBuilder.AppendLine('SEQUENCE:' + Format(JobPlanningLineCalendar.Sequence));
        StringBuilder.AppendLine('STATUS:' + Status);
        StringBuilder.AppendLine('END:VEVENT');
        StringBuilder.AppendLine('END:VCALENDAR');

        ICS := StringBuilder.ToString();
    end;

    local procedure GetAdditionalResources() AdditionalResources: Text
    var
        LocalJobPlanningLine: Record "Job Planning Line";
        LocalResource: Record Resource;
    begin
        // Get all resources for the same job task.
        LocalJobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        LocalJobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        LocalJobPlanningLine.SetRange(Type, LocalJobPlanningLine.Type::Resource);
        LocalJobPlanningLine.SetFilter("Line Type", '%1|%2', LocalJobPlanningLine."Line Type"::Budget, LocalJobPlanningLine."Line Type"::"Both Budget and Billable");
        LocalJobPlanningLine.SetFilter("No.", '<>%1&<>''''', Resource."No.");
        if LocalJobPlanningLine.FindSet() then begin
            AdditionalResources += '\n\n' + AdditionalResourcesTxt + ':';
            repeat
                LocalResource.Get(LocalJobPlanningLine."No.");
                AdditionalResources +=
                    StrSubstNo('\n    (%1) %2 - %3', LocalJobPlanningLine."Line Type", LocalResource.Name, LocalJobPlanningLine.Description);
            until LocalJobPlanningLine.Next() = 0;
        end;
    end;

    local procedure GetContactPhone(): Text[30]
    begin
        if Contact."No." <> '' then
            exit(Contact."Phone No.");

        exit(Customer."Phone No.");
    end;

    local procedure GetDescription() AppointmentDescription: Text
    var
        AppointmentFormat: Text;
    begin
        AppointmentFormat := Job.TableCaption + ': %1 - %2\r\n';
        AppointmentFormat += JobTask.TableCaption + ': %3 - %4\n\n';
        if Customer.Name <> '' then
            AppointmentFormat += StrSubstNo('%1: %2\n', Customer.TableCaption(), Customer.Name);
        AppointmentFormat += Contact.TableCaption + ': %5\n';
        AppointmentFormat += Contact.FieldCaption("Phone No.") + ': %6\n\n';
        AppointmentFormat += Resource.TableCaption + ': (%7) %8 - %9';
        AppointmentDescription := StrSubstNo(AppointmentFormat,
            Job."No.", Job.Description,
            JobTask."Job Task No.", JobTask.Description,
            Customer.Contact, GetContactPhone(),
            JobPlanningLine."Line Type", Resource.Name, JobPlanningLine.Description);

        AppointmentDescription += GetAdditionalResources();
        if ProjectManagerResource.Name <> '' then
            AppointmentDescription += StrSubstNo('\n\n%1: %2',
                Job.FieldCaption("Project Manager"), ProjectManagerResource.Name);
    end;

    local procedure GetHtmlDescription(Description: Text) HtmlAppointDescription: Text
    var
        Regex: Codeunit Regex;
    begin
        HtmlAppointDescription := Regex.Replace(Description, '\\r', '');
        HtmlAppointDescription := Regex.Replace(HtmlAppointDescription, '\\n', '<br>');
        HtmlAppointDescription := 'text/html:<html><body>' + HtmlAppointDescription + '</html></body>';
    end;

    local procedure GetOrganizer(): Text
    var
        ProjectManagerUser: Record User;
        EmailAccount: Record "Email Account";
        EmailScenario: Codeunit "Email Scenario";
    begin
        ProjectManagerUser.SetRange("User Name", ProjectManagerResource."Time Sheet Owner User ID");
        if ProjectManagerUser.FindFirst() then
            if ProjectManagerUser."Authentication Email" <> '' then
                exit(ProjectManagerUser."Authentication Email");

        EmailScenario.GetEmailAccount(Enum::"Email Scenario"::Default, EmailAccount);
        exit(EmailAccount."Email Address");

    end;

    local procedure GetStartDate() StartDateTime: Text
    var
        StartDate: Date;
        StartTime: Time;
    begin
        StartDate := JobPlanningLine."Planning Date";
        if JobPlanningLine.Quantity < 12 then
            Evaluate(StartTime, Format(8));

        StartDateTime := Format(CreateDateTime(StartDate, StartTime), 0, DateTimeFormatTxt);

        OnAfterGetStartDate(JobPlanningLine, StartDateTime);
    end;

    local procedure GetEndDate() EndDateTime: Text
    var
        StartDate: Date;
        EndTime: Time;
        Duration: Decimal;
        Days: Integer;
    begin
        Duration := JobPlanningLine.Quantity;
        StartDate := JobPlanningLine."Planning Date";
        if Duration < 12 then
            Evaluate(EndTime, Format(8 + Duration))
        else
            Days := Round(Duration / 24, 1, '>');

        EndDateTime := Format(CreateDateTime(StartDate + Days, EndTime), 0, DateTimeFormatTxt);

        OnAfterGetEndDate(JobPlanningLine, EndDateTime);
    end;

    local procedure GetResourceEmail(ResourceNo: Code[20]): Text[80]
    var
        LocalResource: Record Resource;
        LocalUser: Record User;
    begin
        LocalResource.Get(ResourceNo);
        LocalUser.SetRange("User Name", LocalResource."Time Sheet Owner User ID");
        if LocalUser.FindFirst() then
            exit(LocalUser."Authentication Email");
    end;

    local procedure UpdateJob()
    begin
        if Job."No." <> JobPlanningLine."Job No." then begin
            Job.Get(JobPlanningLine."Job No.");
            Customer.Get(Job."Bill-to Customer No.");
            if Customer."Primary Contact No." <> '' then
                Contact.Get(Customer."Primary Contact No.");
            if Job."Project Manager" <> '' then
                ProjectManagerResource.Get(Job."Project Manager");
        end;
    end;

    local procedure UpdateJobTask()
    begin
        if (JobTask."Job Task No." <> JobPlanningLine."Job Task No.") or (JobTask."Job No." <> JobPlanningLine."Job No.") then
            JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
    end;

    local procedure UpdateResource()
    begin
        if JobPlanningLine."No." <> Resource."No." then
            if JobPlanningLine."No." <> '' then
                Resource.Get(JobPlanningLine."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeletePlanningLine(var Rec: Record "Job Planning Line"; RunTrigger: Boolean)
    var
        LocalJobPlanningLineCalendar: Record "Job Planning Line - Calendar";
    begin
        if not RunTrigger or Rec.IsTemporary then
            exit;
        if LocalJobPlanningLineCalendar.HasBeenSent(Rec) then begin
            SetPlanningLine(Rec);
            CreateAndSend();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPlanningLine(NewJobPlanningLine: Record "Job Planning Line"; var ProjectManagerResource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetStartDate(JobPlanningLine: Record "Job Planning Line"; var StartDateTime: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetEndDate(JobPlanningLine: Record "Job Planning Line"; var EndDateTime: Text)
    begin
    end;
}

