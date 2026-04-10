#pragma warning disable AA0247
page 26567 "Table Individ. Rqst. Subform"
{
    Caption = 'Individual Requisites';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Table Individual Requisite";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies the description associated with the individual table requisite.';
                }
                field(RequisiteValue; IndRequisiteValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';

                    trigger OnDrillDown()
                    var
                        StatReportDataChangeLog: Record "Stat. Report Data Change Log";
                    begin
                        StatReportDataChangeLog.SetRange("Report Data No.", DataHeaderNo);
                        StatReportDataChangeLog.SetRange("Report Code", ReportCode);
                        StatReportDataChangeLog.SetRange("Table Code", TableCode);
                        StatReportDataChangeLog.SetRange("Row No.", Rec."Line No.");
                        StatReportDataChangeLog.SetRange("Column No.", 0);
                        PAGE.RunModal(PAGE::"Stat. Report Data Change Log", StatReportDataChangeLog);
                    end;

                    trigger OnValidate()
                    begin
                        if StatutoryReportDataValue.Get(DataHeaderNo, ReportCode, TableCode, ExcelSheetName, Rec."Line No.", 0) then begin
                            StatutoryReportDataValue.Validate(Value, IndRequisiteValue);
                            StatutoryReportDataValue.Modify();
                        end else begin
                            StatutoryReportDataValue.Init();
                            StatutoryReportDataValue."Report Data No." := DataHeaderNo;
                            StatutoryReportDataValue."Report Code" := ReportCode;
                            StatutoryReportDataValue."Table Code" := TableCode;
                            StatutoryReportDataValue."Excel Sheet Name" := ExcelSheetName;
                            StatutoryReportDataValue."Row No." := Rec."Line No.";
                            StatutoryReportDataValue."Column No." := 0;
                            StatutoryReportDataValue.Validate(Value, IndRequisiteValue);
                            StatutoryReportDataValue.Insert();
                        end;
                    end;
                }
                field("Row Code"; Rec."Row Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the row code associated with the individual table requisite.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        IndRequisiteValue := '';
        if StatutoryReportDataValue.Get(DataHeaderNo, ReportCode, TableCode, ExcelSheetName, Rec."Line No.", 0) then
            if StatReportDataChangeLog.ShouldValueBeDisplayed(
                 ShowOnlyChangedValues,
                 DataHeaderNo,
                 Rec."Report Code",
                 TableCode,
                 ExcelSheetName,
                 Rec."Line No.",
                 0)
            then
                IndRequisiteValue := StatutoryReportDataValue.Value;
        DescriptionOnFormat();
    end;

    var
        StatutoryReportDataValue: Record "Statutory Report Data Value";
        StatReportDataChangeLog: Record "Stat. Report Data Change Log";
        ReportCode: Code[20];
        TableCode: Code[20];
        DataHeaderNo: Code[20];
        ExcelSheetName: Text[30];
        IndRequisiteValue: Text[150];
        ShowOnlyChangedValues: Boolean;
        DescriptionEmphasize: Boolean;

    [Scope('OnPrem')]
    procedure SetParameters(NewReportCode: Code[20]; NewDataHeaderNo: Code[20]; NewTableCode: Code[20]; NewExcelSheetName: Text[30])
    begin
        ReportCode := NewReportCode;
        TableCode := NewTableCode;
        DataHeaderNo := NewDataHeaderNo;
        ExcelSheetName := NewExcelSheetName;
    end;

    [Scope('OnPrem')]
    procedure UpdateForm(NewReportCode: Code[20]; NewDataHeaderNo: Code[20]; NewTableCode: Code[20]; NewExcelSheetName: Text[30]; NewShowOnlyChangedValues: Boolean)
    begin
        ReportCode := NewReportCode;
        TableCode := NewTableCode;
        DataHeaderNo := NewDataHeaderNo;
        ExcelSheetName := NewExcelSheetName;

        Rec.FilterGroup(2);
        Rec.SetRange("Report Code", ReportCode);
        Rec.SetRange("Table Code", TableCode);
        Rec.FilterGroup(0);

        if Rec.FindFirst() then;
        CurrPage.Update(false);
        ShowOnlyChangedValues := NewShowOnlyChangedValues;
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionEmphasize := Rec.Bold;
    end;
}

