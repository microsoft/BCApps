codeunit 101585 "Create Duplicate Contact"
{

    trigger OnRun()
    begin
    end;

    var
        "Duplicate Contact": Record "Contact Duplicate";

    procedure InsertData("1st Contact No.": Code[20]; "2nd Contact No.": Code[20]; Accepted: Boolean; Matches: Integer)
    begin
        "Duplicate Contact".Init();
        "Duplicate Contact".Validate("Contact No.", "1st Contact No.");
        "Duplicate Contact".Validate("Duplicate Contact No.", "2nd Contact No.");
        "Duplicate Contact".Validate("Separate Contacts", Accepted);
        "Duplicate Contact".Validate("No. of Matching Strings", Matches);
        "Duplicate Contact".Insert();
    end;
}

