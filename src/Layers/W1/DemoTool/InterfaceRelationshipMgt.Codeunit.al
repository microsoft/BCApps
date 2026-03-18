codeunit 114000 "Interface Relationship Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;
        ContactProfileAnswer: Record "Contact Profile Answer";
        XRelationshipManagement: Label 'Relationship Management';

    procedure Create()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, XRelationshipManagement);

        Steps := 0;
        MaxSteps := 40; // Number of calls to RunCodeunit/RunReport

        RunCodeunit(CODEUNIT::"Create Interaction Group");
        RunCodeunit(CODEUNIT::"Create Interact. Templ. Lang.");
        RunCodeunit(CODEUNIT::"Create Interaction Template");
        RunCodeunit(CODEUNIT::"Create Interact. Templ. Setup");
        RunCodeunit(CODEUNIT::"Create Salutation Formula");
        RunCodeunit(CODEUNIT::"Create Mailing Group");
        RunCodeunit(CODEUNIT::"Create Industry Group");
        RunCodeunit(CODEUNIT::"Create Web Source");
        RunCodeunit(CODEUNIT::"Create Job Responsibility");
        RunCodeunit(CODEUNIT::"Create Organizational Level");
        RunCodeunit(CODEUNIT::"Create Team");
        RunCodeunit(CODEUNIT::"Create Team Salesperson");
        RunCodeunit(CODEUNIT::"Create Sales Cycle");
        RunCodeunit(CODEUNIT::"Create Campaign Status");
        RunCodeunit(CODEUNIT::"Create Campaign");
        RunCodeunit(CODEUNIT::"Create Activity");
        RunCodeunit(CODEUNIT::"Create Activity Step");
        RunCodeunit(CODEUNIT::"Create Profile Quest. Header");
        RunCodeunit(CODEUNIT::"Create Profile Quest. Line");
        RunCodeunit(CODEUNIT::"Create Rating");
        RunCodeunit(CODEUNIT::"Create Sales Cycle Stage");
        RunCodeunit(CODEUNIT::"Create Close Opportunity Code");
        RunCodeunit(CODEUNIT::"Create Duplicate Setup");
        RunReport(REPORT::"Create Conts. from Customers");
        RunReport(REPORT::"Create Conts. from Vendors");
        RunReport(REPORT::"Create Conts. from Bank Accs.");
        RunCodeunit(CODEUNIT::"Create Contact");
        RunCodeunit(CODEUNIT::"Create Contact Alt. Addr.");
        RunCodeunit(CODEUNIT::"Create Cont. Alt. Addr. Range");
        RunCodeunit(CODEUNIT::"Create Contact Business Rel.");
        RunCodeunit(CODEUNIT::"Create Contact Mailing Group");
        RunCodeunit(CODEUNIT::"Create Contact Industry Group");
        RunCodeunit(CODEUNIT::"Create Contact Web Source");
        RunCodeunit(CODEUNIT::"Create Contact Job Responsib.");
        RunCodeunit(CODEUNIT::"Create Contact Profile Answer");
        RunCodeunit(CODEUNIT::"Create Opportunity");
        RunCodeunit(CODEUNIT::"Create Opportunity Entry");
        RunCodeunit(CODEUNIT::"Create Task");
        RunCodeunit(CODEUNIT::"Create Attendee");
        RunCodeunit(CODEUNIT::"Create Segment Header");
        RunCodeunit(CODEUNIT::"Create Segment Line");

        Window.Close();
    end;

    procedure "Before Posting"()
    begin
    end;

    procedure Post(PostingDate: Date)
    begin
    end;

    procedure "After Posting"()
    var
        BusInteractionMgtSetup: Record "Marketing Setup";
    begin
        CODEUNIT.Run(CODEUNIT::"Create Interaction Log Entry");
        REPORT.Run(REPORT::"Update Contact Classification", false);
        ContactProfileAnswer.ModifyAll("Last Date Updated", WorkDate());
        BusInteractionMgtSetup.Get();
        BusInteractionMgtSetup.Validate("Autosearch for Duplicates", true);
        BusInteractionMgtSetup.Modify();
    end;

    procedure RunCodeunit(CodeunitID: Integer)
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, CodeunitID);
        Window.Update(1, StrSubstNo('%1 %2', AllObj."Object ID", AllObj."Object Name"));
        Steps := Steps + 1;
        Window.Update(2, Round(Steps / MaxSteps * 10000, 1));
        CODEUNIT.Run(CodeunitID);
    end;

    procedure RunReport(ReportID: Integer)
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Report, ReportID);
        Window.Update(1, StrSubstNo('%1 %2', AllObj."Object ID", AllObj."Object Name"));
        Steps := Steps + 1;
        Window.Update(2, Round(Steps / MaxSteps * 10000, 1));
        REPORT.Run(ReportID, false);
    end;
}

