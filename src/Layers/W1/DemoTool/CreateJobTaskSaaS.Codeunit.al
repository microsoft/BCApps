codeunit 101217 "Create Job Task SaaS"
{

    trigger OnRun()
    begin
        InsertData(XJOB00010, '1000', XPhase1, 3, '');
        InsertData(XJOB00010, '1010', XConsulting, 0, '');
        InsertData(XJOB00010, '1020', XReviewSignOff, 0, '');
        InsertData(XJOB00010, '1099', XPhase1Total, 4, '1000..9990');
        InsertData(XJOB00010, '1100', XPhase2Demo, 3, '');
        InsertData(XJOB00010, '1110', XDemolition, 0, '');
        InsertData(XJOB00010, '1120', XReclaimBricks, 0, '');
        InsertData(XJOB00010, '1199', XPhase2Total, 4, '1100..1199');
        InsertData(XJOB00010, '1200', XPhase3Install, 3, '');
        InsertData(XJOB00010, '1210', XWalls, 0, '');
        InsertData(XJOB00010, '1220', XCeiling, 0, '');
        InsertData(XJOB00010, '1230', XFloors, 0, '');
        InsertData(XJOB00010, '1240', XDecorFurnishings, 0, '');
        InsertData(XJOB00010, '1299', XPhase3Total, 4, '1200..1299');
        InsertData(XJOB00010, '1300', XPhase4Final, 3, '');
        InsertData(XJOB00010, '1310', XTouchUp, 0, '');
        InsertData(XJOB00010, '1320', XReview, 0, '');
        InsertData(XJOB00010, '1399', XPhase4Total, 4, '1300..1399');

        InsertData(XJOB00020, '100', XInitialConsultation, 0, '');
        InsertData(XJOB00020, '200', XPrepForInstall, 0, '');
        InsertData(XJOB00020, '300', XDeliverTableOtherFurnishings, 0, '');

        InsertData(XJOB00030, '100', XInitialConsultation, 0, '');
        InsertData(XJOB00030, '200', XPrepForInstall, 0, '');
        InsertData(XJOB00030, '300', XDeliverChairsOtherFurnishings, 0, '');
    end;

    var
        JobTask: Record "Job Task";
        XJOB00010: Label 'JOB00010', Locked = true;
        XInitialConsultation: Label 'Initial Consultation';
        XPrepForInstall: Label 'Prep for install';
        XPhase1: Label 'Phase 1 - Planning and Specs';
        XConsulting: Label 'Consulting';
        XReviewSignOff: Label 'Review and Sign-off';
        XPhase1Total: Label 'Phase 1 Total';
        XPhase2Demo: Label 'Phase 2 - Demo';
        XDemolition: Label 'Demolition';
        XReclaimBricks: Label 'Reclaim Bricks';
        XPhase2Total: Label 'Phase 2 Total';
        XJOB00020: Label 'JOB00020', Locked = true;
        XPhase3Install: Label 'Phase 3 - Install';
        XWalls: Label 'Walls';
        XCeiling: Label 'Ceiling';
        XFloors: Label 'Floors';
        XDecorFurnishings: Label 'Decorations and Furnishings';
        XPhase3Total: Label 'Phase 3 Total';
        XPhase4Final: Label 'Phase 4 - Final Review';
        XTouchUp: Label 'Touch-Up';
        XReview: Label 'Review';
        XPhase4Total: Label 'Phase 4 Total';
        XJOB00030: Label 'JOB00030', Locked = true;
        XDeliverChairsOtherFurnishings: Label 'Deliver chairs, other furnishings';
        XDeliverTableOtherFurnishings: Label 'Deliver table, other furnishings';

    procedure InsertData("Job No.": Code[20]; "Job Task No.": Code[20]; Description: Text[50]; "Job Task Type": Option Posting,Heading,Total,"Begin-Total","End-Total"; Totalling: Text[250])
    begin
        JobTask.Init();
        JobTask.Validate("Job No.", "Job No.");
        JobTask.Validate("Job Task No.", "Job Task No.");
        JobTask.Validate(Description, Description);
        JobTask.Validate("Job Task Type", "Job Task Type");
        if Totalling <> '' then
            JobTask.Validate(Totaling, Totalling);
        JobTask.Insert();
    end;
}

