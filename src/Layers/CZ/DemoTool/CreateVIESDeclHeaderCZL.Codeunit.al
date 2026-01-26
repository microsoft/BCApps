codeunit 163537 "Create VIES Decl. Header CZL"
{

    trigger OnRun()
    begin
        StartDate := MakeAdjustments.AdjustDate(19030101D);

        InsertData(Date2DMY(StartDate, 3), 1, 1);
    end;

    var
        MakeAdjustments: Codeunit "Make Adjustments";
        StartDate: Date;

    procedure InsertData(Year: Integer; DeclarationPeriod: Option; PeriodNo: Integer)
    var
        VIESDeclarationHeaderCZL: Record "VIES Declaration Header CZL";
    begin
        VIESDeclarationHeaderCZL.Init();
        VIESDeclarationHeaderCZL.Insert(true);
        VIESDeclarationHeaderCZL.Validate(Year, Year);
        VIESDeclarationHeaderCZL.Validate("Declaration Period", DeclarationPeriod);
        VIESDeclarationHeaderCZL.Validate("Period No.", PeriodNo);
        VIESDeclarationHeaderCZL.Modify();
    end;
}

