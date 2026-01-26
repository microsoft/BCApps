codeunit 163526 "Create Compensation Header CZC"
{

    trigger OnRun()
    begin
        InsertData(CompensationHeaderCZC."Company Type"::Customer, '10000', 19030115D, 19030115D);
        InsertData(CompensationHeaderCZC."Company Type"::Vendor, '30000', 19030115D, 19030115D);
    end;

    var
        CompensationHeaderCZC: Record "Compensation Header CZC";
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData(CompanyType: Enum "Compensation Company Type CZC"; CompanyNo: Code[20]; DocumentDate: Date; PostingDate: Date)
    begin
        CompensationHeaderCZC.Init();
        CompensationHeaderCZC."No." := '';
        CompensationHeaderCZC."Company Type" := CompanyType;
        CompensationHeaderCZC.Insert(true);

        CompensationHeaderCZC.Validate("Company No.", CompanyNo);
        CompensationHeaderCZC."Document Date" := MakeAdjustments.AdjustDate(DocumentDate);
        CompensationHeaderCZC."Posting Date" := MakeAdjustments.AdjustDate(PostingDate);
        CompensationHeaderCZC.Modify();
    end;
}

