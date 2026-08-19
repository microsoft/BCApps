codeunit 101160 "Create Resource Capacity Entry"
{

    trigger OnRun()
    begin
        EntryNo := 1;
        InsertData(XLina, CA.AdjustDate(19030101D), CA.AdjustDate(19031231D), 8);
        InsertData(XMARTY, CA.AdjustDate(19030101D), CA.AdjustDate(19031231D), 8);
        InsertData(XTerry, CA.AdjustDate(19030101D), CA.AdjustDate(19031231D), 8);
        Commit();
    end;

    var
        DateRec: Record Date;
        "Res. Capacity Entry": Record "Res. Capacity Entry";
        EntryNo: Integer;
        XLina: Label 'Lina';
        XMarty: Label 'Marty';
        XTerry: Label 'Terry';
        CA: Codeunit "Make Adjustments";

    procedure InsertData("Resource No.": Code[20]; FromDate: Date; ToDate: Date; Capacity: Decimal)
    begin
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetRange("Period Start", FromDate, ToDate);
        DateRec.SetRange("Period No.", 1, 5);
        if DateRec.Find('-') then
            repeat
                "Res. Capacity Entry"."Entry No." := EntryNo;
                EntryNo := EntryNo + 1;
                "Res. Capacity Entry".Validate("Resource No.", "Resource No.");
                "Res. Capacity Entry".Validate(Date, DateRec."Period Start");
                "Res. Capacity Entry".Validate(Capacity, Capacity);
                "Res. Capacity Entry".Insert();
            until DateRec.Next() = 0;
    end;
}

