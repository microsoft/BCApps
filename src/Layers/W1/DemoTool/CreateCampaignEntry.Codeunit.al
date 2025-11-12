codeunit 101572 "Create Campaign Entry"
{

    trigger OnRun()
    begin
        InsertData(1, XCMP1, XMyfirstcampaign, 19030101D, '', '', false, '');
    end;

    var
        "Campaign Entry": Record "Campaign Entry";
        XCMP1: Label 'CMP1';
        XMyfirstcampaign: Label 'My first campaign';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData("Entry No.": Integer; "Campaign No.": Code[10]; Description: Text[30]; Date: Date; "User ID": Code[20]; "Segment No.": Code[10]; Canceled: Boolean; "Salesperson Code": Code[10])
    begin
        "Campaign Entry".Init();
        "Campaign Entry".Validate("Entry No.", "Entry No.");
        "Campaign Entry".Validate("Campaign No.", "Campaign No.");
        "Campaign Entry".Validate(Description, Description);
        "Campaign Entry".Validate(Date, MakeAdjustments.AdjustDate(Date));
        "Campaign Entry".Validate("User ID", "User ID");
        "Campaign Entry".Validate("Segment No.", "Segment No.");
        "Campaign Entry".Validate(Canceled, Canceled);
        "Campaign Entry".Validate("Salesperson Code", "Salesperson Code");
        "Campaign Entry".Insert();
    end;
}

