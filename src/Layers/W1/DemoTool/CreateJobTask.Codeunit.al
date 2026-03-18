codeunit 101211 "Create Job Task"
{

    trigger OnRun()
    begin
        InsertData(XDEERFIELD8WP, '1000', XSettingupEightWorkAreas, 3, '');
        InsertData(XDEERFIELD8WP, '1100', XPreliminaryServices, 3, '');
        InsertData(XDEERFIELD8WP, '1110', XDeterminingSpecifications, 0, '');
        InsertData(XDEERFIELD8WP, '1120', XSelectingFurnishings, 0, '');
        InsertData(XDEERFIELD8WP, '1130', XObtainingCustomerApproval, 0, '');
        InsertData(XDEERFIELD8WP, '1190', XTotalPreliminaryServices, 4, '1100..1190');
        InsertData(XDEERFIELD8WP, '1200', XAssemblingtheFurnitureetc, 3, '');
        InsertData(XDEERFIELD8WP, '1210', XAssemblingtheFurnitureetc, 0, '');
        InsertData(XDEERFIELD8WP, '1290', XTotalAssemblingtheFurnitureTxt, 4, '1200..1290');
        InsertData(XDEERFIELD8WP, '1300', XClosingtheJob, 3, '');
        InsertData(XDEERFIELD8WP, '1310', XMeetingwiththecustomer, 0, '');
        InsertData(XDEERFIELD8WP, '1390', XTotalClosingtheJob, 4, '1300..1390');
        InsertData(XDEERFIELD8WP, '9990', XTotalSettingupEightWorkAreas, 4, '1000..9990');

        InsertData(XGUILDFORD10CR, '1000', XSettingupTenConferenceRooms, 3, '');
        InsertData(XGUILDFORD10CR, '1100', XPreliminaryServices, 3, '');
        InsertData(XGUILDFORD10CR, '1110', XDeterminingSpecifications, 0, '');
        InsertData(XGUILDFORD10CR, '1120', XSelectingFurnishings, 0, '');
        InsertData(XGUILDFORD10CR, '1130', XObtainingCustomerApproval, 0, '');
        InsertData(XGUILDFORD10CR, '1190', XTotalPreliminaryServices, 4, '1100..1190');
        InsertData(XGUILDFORD10CR, '1200', XAssemblingtheFurnitureetc, 3, '');
        InsertData(XGUILDFORD10CR, '1210', XAssemblingtheFurnitureetc, 0, '');
        InsertData(XGUILDFORD10CR, '1290', XTotalAssemblingtheFurnitureTxt, 4, '1200..1290');
        InsertData(XGUILDFORD10CR, '1300', XClosingtheJob, 3, '');
        InsertData(XGUILDFORD10CR, '1310', XMeetingwiththecustomer, 0, '');
        InsertData(XGUILDFORD10CR, '1390', XTotalClosingtheJob, 4, '1300..1390');
        InsertData(XGUILDFORD10CR, '9990', XTotalSettingup10CR, 4, '1000..9990');
    end;

    var
        JobTask: Record "Job Task";
        XDEERFIELD8WP: Label 'DEERFIELD, 8 WP';
        XSettingupEightWorkAreas: Label 'Setting up Eight Work Areas';
        XPreliminaryServices: Label 'Preliminary Services';
        XDeterminingSpecifications: Label 'Determining Specifications';
        XSelectingFurnishings: Label 'Selecting Furnishings';
        XObtainingCustomerApproval: Label 'Obtaining Customer Approval';
        XTotalPreliminaryServices: Label 'Total Preliminary Services';
        XAssemblingtheFurnitureetc: Label 'Assembling the Furniture etc.';
        XTotalAssemblingtheFurnitureTxt: Label 'Total Assembling the Furniture';
        XClosingtheJob: Label 'Closing the Job';
        XMeetingwiththecustomer: Label 'Meeting with the Customer';
        XTotalClosingtheJob: Label 'Total Closing the Job';
        XTotalSettingupEightWorkAreas: Label 'Total Setting up Eight Work Areas';
        XGUILDFORD10CR: Label 'GUILDFORD, 10 CR';
        XSettingupTenConferenceRooms: Label 'Setting up Ten Conference Rooms';
        XTotalSettingup10CR: Label 'Total Setting up Ten Conference Rooms';

    procedure InsertData("Job No.": Code[20]; "Job Task No.": Code[20]; Description: Text[50]; "Job Task Type": Option Posting,Heading,Total,"Begin-Total","End-Total"; Totalling: Text[250])
    begin
        JobTask.Init();
        JobTask.Validate("Job No.", "Job No.");
        JobTask.Validate("Job Task No.", "Job Task No.");
        JobTask.Validate(Description, Description);
        JobTask.Validate("Job Task Type", "Job Task Type");
        if Totalling <> '' then
            JobTask.Validate(Totaling, Totalling);
        JobTask.Insert(true);
    end;
}

