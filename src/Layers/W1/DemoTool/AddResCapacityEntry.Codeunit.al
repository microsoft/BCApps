codeunit 117563 "Add Res. Capacity Entry"
{

    trigger OnRun()
    begin
        "Res. Capacity Entry".Reset();
        if "Res. Capacity Entry".FindLast() then
            EntryNo := "Res. Capacity Entry"."Entry No." + 1
        else
            EntryNo := 1;
        InsertData(XKatherine, 19030101D, 19031231D, 8);
        Commit();
    end;

    var
        DateRec: Record Date;
        "Res. Capacity Entry": Record "Res. Capacity Entry";
        EntryNo: Integer;
        XKatherine: Label 'Katherine';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData("Resource No.": Code[20]; FromDate: Date; ToDate: Date; Capacity: Decimal)
    begin
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetRange(
          "Period Start", MakeAdjustments.AdjustDate(FromDate), MakeAdjustments.AdjustDate(ToDate));
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

