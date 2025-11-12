// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.WIP;

table 1017 "Job Buffer"
{
    Caption = 'Project Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Account No. 1"; Code[20])
        {
            Caption = 'Account No. 1';
            DataClassification = SystemMetadata;
        }
        field(2; "Account No. 2"; Code[20])
        {
            Caption = 'Account No. 2';
            DataClassification = SystemMetadata;
        }
        field(3; "Amount 1"; Decimal)
        {
            Caption = 'Amount 1';
            DataClassification = SystemMetadata;
        }
        field(4; "Amount 2"; Decimal)
        {
            Caption = 'Amount 2';
            DataClassification = SystemMetadata;
        }
        field(5; "Amount 3"; Decimal)
        {
            Caption = 'Amount 3';
            DataClassification = SystemMetadata;
        }
        field(6; "Amount 4"; Decimal)
        {
            Caption = 'Amount 4';
            DataClassification = SystemMetadata;
        }
        field(7; "Amount 5"; Decimal)
        {
            Caption = 'Amount 5';
            DataClassification = SystemMetadata;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(11; "New Total"; Boolean)
        {
            Caption = 'New Total';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Account No. 1", "Account No. 2")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TempJobBuffer: array[2] of Record "Job Buffer" temporary;

    procedure InsertWorkInProgress(var Job: Record Job)
    var
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        Clear(TempJobBuffer);
        JobWIPGLEntry.SetCurrentKey("Job No.");
        JobWIPGLEntry.SetRange("Job No.", Job."No.");
        JobWIPGLEntry.SetRange(Reversed, false);
        JobWIPGLEntry.SetRange("Job Complete", false);

        JobWIPGLEntry.SetFilter("Posting Date", Job.GetFilter("Posting Date Filter"));
        if JobWIPGLEntry.Find('-') then
            repeat
                Clear(TempJobBuffer);
                if JobWIPGLEntry."G/L Account No." <> '' then begin
                    TempJobBuffer[1]."Account No. 1" := JobWIPGLEntry."G/L Account No.";
                    TempJobBuffer[1]."Account No. 2" := JobWIPGLEntry."Job Posting Group";
                    if (JobWIPGLEntry.Type = JobWIPGLEntry.Type::"Applied Costs") or
                       (JobWIPGLEntry.Type = JobWIPGLEntry.Type::"Recognized Costs")
                    then
                        TempJobBuffer[1]."Amount 1" := JobWIPGLEntry."WIP Entry Amount"
                    else
                        if JobWIPGLEntry.Type = JobWIPGLEntry.Type::"Accrued Costs" then
                            TempJobBuffer[1]."Amount 2" := JobWIPGLEntry."WIP Entry Amount";
                    if (JobWIPGLEntry.Type = JobWIPGLEntry.Type::"Applied Sales") or
                       (JobWIPGLEntry.Type = JobWIPGLEntry.Type::"Recognized Sales")
                    then
                        TempJobBuffer[1]."Amount 4" := JobWIPGLEntry."WIP Entry Amount"
                    else
                        if JobWIPGLEntry.Type = JobWIPGLEntry.Type::"Accrued Sales" then
                            TempJobBuffer[1]."Amount 5" := JobWIPGLEntry."WIP Entry Amount";
                    TempJobBuffer[2] := TempJobBuffer[1];
                    if TempJobBuffer[2].Find() then begin
                        TempJobBuffer[2]."Amount 1" :=
                          TempJobBuffer[2]."Amount 1" + TempJobBuffer[1]."Amount 1";
                        TempJobBuffer[2]."Amount 2" :=
                          TempJobBuffer[2]."Amount 2" + TempJobBuffer[1]."Amount 2";
                        TempJobBuffer[2]."Amount 4" :=
                          TempJobBuffer[2]."Amount 4" + TempJobBuffer[1]."Amount 4";
                        TempJobBuffer[2]."Amount 5" :=
                          TempJobBuffer[2]."Amount 5" + TempJobBuffer[1]."Amount 5";
                        TempJobBuffer[2].Modify();
                    end else
                        TempJobBuffer[1].Insert();
                end;
            until JobWIPGLEntry.Next() = 0;
    end;

    procedure InitJobBuffer()
    begin
        Clear(TempJobBuffer);
        TempJobBuffer[1].DeleteAll();
    end;

    procedure GetJobBuffer(var Job: Record Job; var JobBuffer2: Record "Job Buffer")
    var
        GLEntry: Record "G/L Entry";
        OldAcc: Code[20];
    begin
        JobBuffer2.DeleteAll();
        GLEntry.SetCurrentKey("G/L Account No.", "Job No.", "Posting Date");
        GLEntry.SetFilter("Posting Date", Job.GetFilter("Posting Date Filter"));
        OldAcc := '';

        if TempJobBuffer[1].Find('+') then
            repeat
                if TempJobBuffer[1]."Account No. 1" <> OldAcc then begin
                    GLEntry.SetRange("G/L Account No.", TempJobBuffer[1]."Account No. 1");
                    GLEntry.SetFilter("Job No.", Job.GetFilter("No."));
                    GLEntry.CalcSums(Amount);
                    TempJobBuffer[1]."Amount 3" := GLEntry.Amount;
                    if TempJobBuffer[1]."Amount 3" <> 0 then
                        TempJobBuffer[1]."New Total" := true;
                    OldAcc := TempJobBuffer[1]."Account No. 1";
                end;
                JobBuffer2 := TempJobBuffer[1];
                JobBuffer2.Insert();
            until TempJobBuffer[1].Next(-1) = 0;
        TempJobBuffer[1].DeleteAll();
    end;

    procedure ReportJobItem(var Job: Record Job; var item2: Record Item; var JobBuffer2: Record "Job Buffer")
    var
        Item: Record Item;
        Item3: Record Item;
        JobLedgEntry: Record "Job Ledger Entry";
        InFilter: Boolean;
        Itemfilter: Boolean;
    begin
        Clear(JobBuffer2);
        Clear(TempJobBuffer);
        JobBuffer2.DeleteAll();
        TempJobBuffer[1].DeleteAll();
        if Job."No." = '' then
            exit;
        Item.Copy(item2);
        Itemfilter := Item.GetFilters <> '';
        Item.SetCurrentKey("No.");

        JobLedgEntry.SetCurrentKey("Job No.", "Posting Date");
        JobLedgEntry.SetRange("Job No.", Job."No.");
        JobLedgEntry.SetFilter("Posting Date", Job.GetFilter("Posting Date Filter"));
        if JobLedgEntry.Find('-') then
            repeat
                if (JobLedgEntry."Entry Type" = JobLedgEntry."Entry Type"::Usage) and
                   (JobLedgEntry.Type = JobLedgEntry.Type::Item) and
                   (JobLedgEntry."No." <> '')
                then begin
                    InFilter := true;
                    if Itemfilter then begin
                        Item.Init();
                        Item."No." := JobLedgEntry."No.";
                        InFilter := Item.Find();
                    end;
                    if InFilter then begin
                        Item3.Init();
                        if Item3.Get(JobLedgEntry."No.") then;
                        Clear(TempJobBuffer[1]);
                        TempJobBuffer[1]."Account No. 1" := JobLedgEntry."No.";
                        TempJobBuffer[1]."Account No. 2" := JobLedgEntry."Unit of Measure Code";
                        TempJobBuffer[1].Description := Item3.Description;
                        TempJobBuffer[1]."Amount 1" := JobLedgEntry.Quantity;
                        TempJobBuffer[1]."Amount 2" := JobLedgEntry."Total Cost (LCY)";
                        TempJobBuffer[1]."Amount 3" := JobLedgEntry."Line Amount (LCY)";
                        TempJobBuffer[2] := TempJobBuffer[1];
                        OnReportJobItemOnBeforeUpsertJobBuffer(TempJobBuffer, JobLedgEntry, Item3);
                        if TempJobBuffer[2].Find() then begin
                            TempJobBuffer[2]."Amount 1" :=
                              TempJobBuffer[2]."Amount 1" + TempJobBuffer[1]."Amount 1";
                            TempJobBuffer[2]."Amount 2" :=
                              TempJobBuffer[2]."Amount 2" + TempJobBuffer[1]."Amount 2";
                            TempJobBuffer[2]."Amount 3" :=
                              TempJobBuffer[2]."Amount 3" + TempJobBuffer[1]."Amount 3";
                            OnReportJobItemOnBeforeModifyJobBuffer(TempJobBuffer, JobLedgEntry);
                            TempJobBuffer[2].Modify();
                        end else
                            TempJobBuffer[1].Insert();
                    end;
                end;
            until JobLedgEntry.Next() = 0;

        if TempJobBuffer[1].Find('-') then
            repeat
                JobBuffer2 := TempJobBuffer[1];
                JobBuffer2.Insert();
            until TempJobBuffer[1].Next() = 0;
        TempJobBuffer[1].DeleteAll();
    end;

    procedure ReportItemJob(var Item: Record Item; var Job2: Record Job; var JobBuffer2: Record "Job Buffer")
    var
        JobLedgEntry: Record "Job Ledger Entry";
        Job: Record Job;
        Job3: Record Job;
        InFilter: Boolean;
        JobFilter: Boolean;
    begin
        Clear(JobBuffer2);
        Clear(TempJobBuffer);
        JobBuffer2.DeleteAll();
        TempJobBuffer[1].DeleteAll();
        if Item."No." = '' then
            exit;
        Job.Copy(Job2);
        JobFilter := Job.GetFilters <> '';
        Job.SetCurrentKey("No.");

        JobLedgEntry.SetCurrentKey("Entry Type", Type, "No.", "Posting Date");
        JobLedgEntry.SetRange("Entry Type", JobLedgEntry."Entry Type"::Usage);
        JobLedgEntry.SetRange(Type, JobLedgEntry.Type::Item);
        JobLedgEntry.SetRange("No.", Item."No.");
        JobLedgEntry.SetFilter("Posting Date", Job.GetFilter("Posting Date Filter"));
        if JobLedgEntry.Find('-') then
            repeat
                InFilter := true;
                if JobFilter then begin
                    Job.Init();
                    Job."No." := JobLedgEntry."Job No.";
                    InFilter := Job.Find();
                end;
                if InFilter then begin
                    Job3.Init();
                    if Job3.Get(JobLedgEntry."Job No.") then;
                    Clear(TempJobBuffer[1]);
                    TempJobBuffer[1]."Account No. 1" := JobLedgEntry."Job No.";
                    TempJobBuffer[1]."Account No. 2" := JobLedgEntry."Unit of Measure Code";
                    TempJobBuffer[1].Description := Job3.Description;
                    TempJobBuffer[1]."Amount 1" := JobLedgEntry.Quantity;
                    TempJobBuffer[1]."Amount 2" := JobLedgEntry."Total Cost (LCY)";
                    TempJobBuffer[1]."Amount 3" := JobLedgEntry."Line Amount (LCY)";
                    TempJobBuffer[2] := TempJobBuffer[1];
                    if TempJobBuffer[2].Find() then begin
                        TempJobBuffer[2]."Amount 1" :=
                          TempJobBuffer[2]."Amount 1" + TempJobBuffer[1]."Amount 1";
                        TempJobBuffer[2]."Amount 2" :=
                          TempJobBuffer[2]."Amount 2" + TempJobBuffer[1]."Amount 2";
                        TempJobBuffer[2]."Amount 3" :=
                          TempJobBuffer[2]."Amount 3" + TempJobBuffer[1]."Amount 3";
                        TempJobBuffer[2].Modify();
                    end else
                        TempJobBuffer[1].Insert();
                end;
            until JobLedgEntry.Next() = 0;

        if TempJobBuffer[1].Find('-') then
            repeat
                JobBuffer2 := TempJobBuffer[1];
                JobBuffer2.Insert();
            until TempJobBuffer[1].Next() = 0;
        TempJobBuffer[1].DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReportJobItemOnBeforeUpsertJobBuffer(var TempJobBuffer: array[2] of Record "Job Buffer" temporary; JobLedgerEntry: Record "Job Ledger Entry"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReportJobItemOnBeforeModifyJobBuffer(var TempJobBuffer: array[2] of Record "Job Buffer" temporary; JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;
}

