codeunit 101169 "Create Jobs For SaaS"
{

    trigger OnRun()
    var
        CreateJobResources: Codeunit "Create Job Resources";
        CreationDate: Date;
        StartingDate: Date;
        EndingDate: Date;
        LastDateModified: Date;
    begin
        CreationDate := 19010201D;
        StartingDate := 19010301D;
        EndingDate := 19010331D;
        LastDateModified := 19010201D;

        InsertData(
          XJOB00010, XReceptionAreRemodel, '30000', CA.AdjustDate(CreationDate),
          CA.AdjustDate(StartingDate), CA.AdjustDate(EndingDate), "Job Status"::Open, CreateJobResources.LinaCode(),
          XSETTINGUP, CA.AdjustDate(LastDateModified), XCOMPLETEDCONTRACT);
        InsertData(
          XJOB00020, XDecorateConferenceRoom, '10000', CA.AdjustDate(CreationDate),
          CA.AdjustDate(StartingDate), CA.AdjustDate(EndingDate), "Job Status"::Open, CreateJobResources.LinaCode(),
          XSETTINGUP, CA.AdjustDate(LastDateModified), XCOMPLETEDCONTRACT);
        InsertData(
          XJOB00030, XNewOfficeFurniture, '20000', CA.AdjustDate(CreationDate),
          CA.AdjustDate(StartingDate), CA.AdjustDate(EndingDate), "Job Status"::Open, CreateJobResources.KatherineCode(),
          XSETTINGUP, CA.AdjustDate(LastDateModified), XCOMPLETEDCONTRACT);
    end;

    var
        Job: Record Job;
        CA: Codeunit "Make Adjustments";
        XJOB00010: Label 'JOB00010', Locked = true;
        XReceptionAreRemodel: Label 'Reception area remodel';
        XSETTINGUP: Label 'SETTING UP';
        XJOB00020: Label 'JOB00020', Locked = true;
        XDecorateConferenceRoom: Label 'Decorate Conference Room';
        XCOMPLETEDCONTRACT: Label 'COMPLETED CONTRACT';
        XJOB00030: Label 'JOB00030', Locked = true;
        XNewOfficeFurniture: Label 'New Office Furniture';

    procedure InsertData(No: Code[20]; Description: Text[50]; BilltoCustomerNo: Code[20]; CreationDate: Date; StartingDate: Date; EndingDate: Date; Status: Enum "Job Status"; PersonResponsible: Code[20]; PostingGroup: Code[20]; LastDateModified: Date; WipMethod: Code[20])
    begin
        Job.Init();
        Job."No." := No;
        Job.Description := Description;
        Job.Validate("Bill-to Customer No.", BilltoCustomerNo);
        Job."Creation Date" := CreationDate;
        Job."Starting Date" := StartingDate;
        Job."Ending Date" := EndingDate;
        Job.Status := Status;
        Job."Person Responsible" := PersonResponsible;
        Job."Job Posting Group" := PostingGroup;
        Job."Last Date Modified" := LastDateModified;
        Job."WIP Method" := WipMethod;
        Job.Validate("Apply Usage Link", true);
        Job.Insert();
    end;
}

