codeunit 101167 "Create Job"
{

    trigger OnRun()
    begin
        InsertData(
          XDEERFIELD8WP, XSettingupEightWorkAreas, '40000', CA.AdjustDate(19021208D),
          CA.AdjustDate(19030116D), CA.AdjustDate(19030203D), "Job Status"::Open, XLina,
          XSETTINGUP, CA.AdjustDate(19030126D), XCOMPLETEDCONTRACT);
        InsertData(
          XGUILDFORD10CR, XSettingupTenConferenceRooms, '50000', CA.AdjustDate(19021212D),
          CA.AdjustDate(19030101D), CA.AdjustDate(19030131D), "Job Status"::Open, XLina,
          XSETTINGUP, CA.AdjustDate(19030126D), XSALESVALUE);
    end;

    var
        Job: Record Job;
        CA: Codeunit "Make Adjustments";
        XDEERFIELD8WP: Label 'DEERFIELD, 8 WP';
        XSettingupEightWorkAreas: Label 'Setting up Eight Work Areas';
        XLina: Label 'Lina';
        XSETTINGUP: Label 'SETTING UP';
        XGUILDFORD10CR: Label 'GUILDFORD, 10 CR';
        XSettingupTenConferenceRooms: Label 'Setting up Ten Conference Rooms';
        XSALESVALUE: Label 'SALES VALUE';
        XCOMPLETEDCONTRACT: Label 'COMPLETED CONTRACT';

    procedure InsertData(No: Code[20]; Description: Text[50]; BilltoCustomerNo: Code[20]; CreationDate: Date; StartingDate: Date; EndingDate: Date; Status: Enum "Job Status"; PersonResponsible: Code[20]; PostingGroup: Code[20]; LastDateModified: Date; WipMethod: Code[20])
    begin
        Job.Init();
        Job.Validate("No.", No);
        Job.Validate(Description, Description);
        Job.Validate("Bill-to Customer No.", BilltoCustomerNo);
        Job.Validate("Creation Date", CreationDate);
        Job.Validate("Starting Date", StartingDate);
        Job.Validate("Ending Date", EndingDate);
        Job.Status := Status;
        Job.Validate("Person Responsible", PersonResponsible);
        Job.Validate("Job Posting Group", PostingGroup);
        Job.Validate("Last Date Modified", LastDateModified);
        Job.Validate("WIP Method", WipMethod);

        Job.Insert();
        Job.CopyDefaultDimensionsFromCustomer();
    end;
}

