codeunit 101160 "Create Resource Capacity Entry"
{

    trigger OnRun()
    begin
        EntryNo := 1;
        InsertData(XLina, 19021226D, 37);
        InsertData(XMarty, 19021226D, 37);
        InsertData(XTerry, 19021226D, 37);
        InsertData(XLina, 19021226D, -37);
        InsertData(XMarty, 19021226D, -37);
        InsertData(XTerry, 19021226D, -37);
        InsertData(XLina, 19030102D, 40);
        InsertData(XMarty, 19030102D, 40);
        InsertData(XTerry, 19030102D, 40);
        InsertData(XLina, 19030109D, 40);
        InsertData(XMarty, 19030109D, 40);
        InsertData(XTerry, 19030109D, 40);
        InsertData(XLina, 19030116D, 40);
        InsertData(XMarty, 19030116D, 40);
        InsertData(XTerry, 19030116D, 40);
        InsertData(XLina, 19030123D, 40);
        InsertData(XMarty, 19030123D, 40);
        InsertData(XTerry, 19030123D, 40);
        InsertData(XLina, 19030130D, 40);
        InsertData(XMarty, 19030130D, 40);
        InsertData(XTerry, 19030130D, 40);
        InsertData(XLina, 19030206D, 40);
        InsertData(XMarty, 19030206D, 40);
        InsertData(XTerry, 19030206D, 40);
        InsertData(XTerry, 19030213D, 40);
        InsertData(XLina, 19030213D, 40);
        InsertData(XLina, 19030220D, 40);
        InsertData(XMarty, 19030220D, 40);
        InsertData(XMarty, 19030206D, -40);
        Commit();
    end;

    var
        "Res. Capacity Entry": Record "Res. Capacity Entry";
        EntryNo: Integer;
        XLina: Label 'Lina';
        XMarty: Label 'Marty';
        XTerry: Label 'Terry';
        CA: Codeunit "Make Adjustments";

    procedure InsertData("Resource No.": Code[20]; Date: Date; Capacity: Decimal)
    begin
        Date := CA.AdjustDate(Date);
        EntryNo := EntryNo + 1;
        "Res. Capacity Entry"."Entry No." := EntryNo;
        "Res. Capacity Entry".Validate("Resource No.", "Resource No.");
        "Res. Capacity Entry".Validate(Date, Date);
        "Res. Capacity Entry".Validate(Capacity, Capacity);
        "Res. Capacity Entry".Insert();
    end;
}

