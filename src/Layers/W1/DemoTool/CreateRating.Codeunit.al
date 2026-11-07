codeunit 101598 "Create Rating"
{

    trigger OnRun()
    begin
        InsertData(XLEADQ, 240000, XLEADQ, 20000, 200);
        InsertData(XLEADQ, 240000, XLEADQ, 30000, 100);
        InsertData(XLEADQ, 240000, XLEADQ, 40000, 1);
        InsertData(XLEADQ, 240000, XLEADQ, 60000, 200);
        InsertData(XLEADQ, 240000, XLEADQ, 70000, 100);
        InsertData(XLEADQ, 240000, XLEADQ, 80000, -100);
        InsertData(XLEADQ, 240000, XLEADQ, 100000, 200);
        InsertData(XLEADQ, 240000, XLEADQ, 110000, 100);
        InsertData(XLEADQ, 240000, XLEADQ, 120000, -100);
        InsertData(XLEADQ, 240000, XLEADQ, 140000, 200);
        InsertData(XLEADQ, 240000, XLEADQ, 150000, 100);
        InsertData(XLEADQ, 240000, XLEADQ, 160000, 1);
        InsertData(XLEADQ, 240000, XLEADQ, 180000, 300);
        InsertData(XLEADQ, 240000, XLEADQ, 190000, 100);
        InsertData(XLEADQ, 240000, XLEADQ, 200000, -100);
        InsertData(XLEADQ, 240000, XLEADQ, 220000, 300);
        InsertData(XLEADQ, 240000, XLEADQ, 230000, 1);
        InsertData(XPORTF, 10000, XPORTF, 70000, 40);
        InsertData(XPORTF, 10000, XPORTF, 80000, 10);
        InsertData(XPORTF, 10000, XPORTF, 100000, 20);
        InsertData(XPORTF, 10000, XPORTF, 110000, 5);
        InsertData(XPORTF, 60000, XCUSTOMER, 20000, 200);
        InsertData(XPORTF, 60000, XCUSTOMER, 25000, 100);
        InsertData(XPORTF, 60000, XCUSTOMER, 30000, 1);
        InsertData(XPORTF, 60000, XCUSTOMER, 50000, 200);
        InsertData(XPORTF, 60000, XCUSTOMER, 55000, 100);
        InsertData(XPORTF, 60000, XCUSTOMER, 60000, 1);
        InsertData(XPORTF, 90000, XPOTENTIAL, 20000, 200);
        InsertData(XPORTF, 90000, XPOTENTIAL, 30000, 100);
        InsertData(XPORTF, 90000, XPOTENTIAL, 40000, 1);
        InsertData(XPORTF, 90000, XPOTENTIAL, 60000, 200);
        InsertData(XPORTF, 90000, XPOTENTIAL, 70000, 100);
        InsertData(XPORTF, 90000, XPOTENTIAL, 80000, 1);
        InsertData(XPORTF, 90000, XPOTENTIAL, 100000, 300);
        InsertData(XPORTF, 90000, XPOTENTIAL, 110000, 200);
        InsertData(XPORTF, 90000, XPOTENTIAL, 120000, 100);
        InsertData(XPORTF, 90000, XPOTENTIAL, 130000, -100);
        InsertData(XPORTF, 90000, XPOTENTIAL, 160000, 200);
        InsertData(XPORTF, 90000, XPOTENTIAL, 170000, 100);
        InsertData(XPORTF, 90000, XPOTENTIAL, 180000, 1);
        InsertData(XSATISF, 10000, XSATISF, 6250, 300);
        InsertData(XSATISF, 10000, XSATISF, 6875, 200);
        InsertData(XSATISF, 10000, XSATISF, 7187, 100);
        InsertData(XSATISF, 10000, XSATISF, 7500, -100);
        InsertData(XSATISF, 10000, XSATISF, 9062, 300);
        InsertData(XSATISF, 10000, XSATISF, 9218, 200);
        InsertData(XSATISF, 10000, XSATISF, 9296, 100);
        InsertData(XSATISF, 10000, XSATISF, 9375, -100);
        InsertData(XSATISF, 10000, XSATISF, 9765, 300);
        InsertData(XSATISF, 10000, XSATISF, 9804, 200);
        InsertData(XSATISF, 10000, XSATISF, 9823, 100);
        InsertData(XSATISF, 10000, XSATISF, 9843, -100);
        InsertData(XSATISF, 10000, XSATISF, 9940, 300);
        InsertData(XSATISF, 10000, XSATISF, 9950, 200);
        InsertData(XSATISF, 10000, XSATISF, 9955, 100);
        InsertData(XSATISF, 10000, XSATISF, 9960, -100);
    end;

    var
        Rating: Record Rating;
        XLEADQ: Label 'LEADQ';
        XPORTF: Label 'PORTF';
        XCUSTOMER: Label 'CUSTOMER';
        XPOTENTIAL: Label 'POTENTIAL';
        XSATISF: Label 'SATISF';

    procedure InsertData("Profile Questionnaire Code": Code[10]; "Profile Questionnaire Line No.": Integer; "Rating Profile Quest. Code": Code[10]; "Rating Profile Quest. Line No.": Integer; Points: Decimal)
    begin
        Rating.Init();
        Rating.Validate("Profile Questionnaire Code", "Profile Questionnaire Code");
        Rating.Validate("Profile Questionnaire Line No.", "Profile Questionnaire Line No.");
        Rating.Validate("Rating Profile Quest. Code", "Rating Profile Quest. Code");
        Rating.Validate("Rating Profile Quest. Line No.", "Rating Profile Quest. Line No.");
        Rating.Validate(Points, Points);
        Rating.Insert();
    end;
}

