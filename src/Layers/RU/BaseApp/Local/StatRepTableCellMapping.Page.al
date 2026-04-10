#pragma warning disable AA0247
page 26594 "Stat. Rep. Table Cell Mapping"
{
    Caption = 'Stat. Rep. Table Cell Mapping';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Stat. Report Table Mapping";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Report Code"; Rec."Report Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the report code for statutory reports.';
                }
                field("Table Code"; Rec."Table Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the table code associated with the statutory report.';
                }
                field("Table Row Description"; Rec."Table Row Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the table row description associated with the statutory report.';
                }
                field("Table Column Header"; Rec."Table Column Header")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the table column header associated with the statutory report.';
                }
                field("Int. Source Type"; Rec."Int. Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal source type for the statutory report.';

                    trigger OnValidate()
                    begin
                        IntSourceTypeOnAfterValidate();
                    end;
                }
                field("Int. Source Section Code"; Rec."Int. Source Section Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Int. Source Section CodeEnable";
                    ToolTip = 'Specifies the internal source section code associated with the statutory report.';
                }
                field("Int. Source No."; Rec."Int. Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal source number for statutory reports.';
                }
                field("Int. Source Row Description"; Rec."Int. Source Row Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the internal source row description associated with the statutory report.';

                    trigger OnDrillDown()
                    begin
                        case Rec."Int. Source Type" of
                            Rec."Int. Source Type"::"Acc. Schedule":
                                begin
                                    AccScheduleLine.FilterGroup(2);
                                    AccScheduleLine.SetRange("Schedule Name", Rec."Int. Source No.");
                                    AccScheduleLine.FilterGroup(0);
                                    Clear(AccScheduleLines);
                                    AccScheduleLines.SetTableView(AccScheduleLine);
                                    if Rec."Internal Source Row No." <> 0 then
                                        if AccScheduleLine.Get(Rec."Int. Source No.", Rec."Internal Source Row No.") then
                                            AccScheduleLines.SetRecord(AccScheduleLine);
                                    AccScheduleLines.LookupMode := true;
                                    if AccScheduleLines.RunModal() = ACTION::LookupOK then begin
                                        AccScheduleLines.GetRecord(AccScheduleLine);
                                        Rec."Internal Source Row No." := AccScheduleLine."Line No.";
                                        Rec."Int. Source Row Description" := AccScheduleLine.Description;
                                    end;
                                end;
                            Rec."Int. Source Type"::"Tax Register":
                                begin
                                    TaxRegisterTemplate.FilterGroup(2);
                                    TaxRegisterTemplate.SetRange("Section Code", Rec."Int. Source Section Code");
                                    TaxRegisterTemplate.SetRange(Code, Rec."Int. Source No.");
                                    TaxRegisterTemplate.FilterGroup(0);
                                    Clear(TaxRegisterTemplateLines);
                                    TaxRegisterTemplateLines.SetTableView(TaxRegisterTemplate);
                                    if Rec."Internal Source Row No." <> 0 then
                                        if TaxRegisterTemplate.Get(
                                             Rec."Int. Source Section Code",
                                             Rec."Int. Source No.",
                                             Rec."Internal Source Row No.")
                                        then
                                            TaxRegisterTemplateLines.SetRecord(TaxRegisterTemplate);
                                    TaxRegisterTemplateLines.LookupMode := true;
                                    if TaxRegisterTemplateLines.RunModal() = ACTION::LookupOK then begin
                                        TaxRegisterTemplateLines.GetRecord(TaxRegisterTemplate);
                                        Rec."Internal Source Row No." := TaxRegisterTemplate."Line No.";
                                        Rec."Int. Source Row Description" := TaxRegisterTemplate.Description;
                                    end;
                                end;
                            Rec."Int. Source Type"::"Tax Difference":
                                begin
                                    TaxCalcLine.FilterGroup(2);
                                    TaxCalcLine.SetRange("Section Code", Rec."Int. Source Section Code");
                                    TaxCalcLine.SetRange(Code, Rec."Int. Source No.");
                                    TaxCalcLine.FilterGroup(0);
                                    Clear(TaxCalcLines);
                                    TaxCalcLines.SetTableView(TaxCalcLine);
                                    if Rec."Internal Source Row No." <> 0 then
                                        if TaxCalcLine.Get(
                                             Rec."Int. Source Section Code",
                                             Rec."Int. Source No.",
                                             Rec."Internal Source Row No.")
                                        then
                                            TaxCalcLines.SetRecord(TaxCalcLine);
                                    TaxCalcLines.LookupMode := true;
                                    if TaxCalcLines.RunModal() = ACTION::LookupOK then begin
                                        TaxCalcLines.GetRecord(TaxCalcLine);
                                        Rec."Internal Source Row No." := TaxCalcLine."Line No.";
                                        Rec."Int. Source Row Description" := TaxCalcLine.Description;
                                    end;
                                end;
                        end;
                    end;
                }
                field("Int. Source Col. Lay. Name"; Rec."Int. Source Col. Lay. Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal source column layout name associated with the statutory report.';
                    trigger OnDrillDown()
                    var
                        ColumnLayoutName: Record "Column Layout Name";
                        ColumnLayoutNames: Page "Column Layout Names";
                    begin
                        if Rec."Int. Source Type" <> Rec."Int. Source Type"::"Acc. Schedule" then
                            exit;
                        if ColumnLayoutNames.RunModal() <> Action::LookupOK then
                            exit;
                        ColumnLayoutNames.GetRecord(ColumnLayoutName);
                        Rec."Int. Source Col. Lay. Name" := ColumnLayoutName.Name;
                    end;
                }
                field("Int. Source Column Header"; Rec."Int. Source Column Header")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = IntSourceColumnHeaderEnable;
                    ToolTip = 'Specifies the internal source column header associated with the statutory report.';

                    trigger OnDrillDown()
                    begin
                        case Rec."Int. Source Type" of
                            Rec."Int. Source Type"::"Acc. Schedule":
                                begin
                                    Rec.TestField("Int. Source Col. Lay. Name");
                                    ColumnLayout.FilterGroup(2);
                                    ColumnLayout.SetRange("Column Layout Name", Rec."Int. Source Col. Lay. Name");
                                    ColumnLayout.FilterGroup(0);
                                    Clear(ColumnLayouts);
                                    ColumnLayouts.SetTableView(ColumnLayout);
                                    if Rec."Internal Source Column No." <> 0 then
                                        if ColumnLayout.Get(Rec."Int. Source Col. Lay. Name", Rec."Internal Source Column No.") then
                                            ColumnLayouts.SetRecord(ColumnLayout);
                                    ColumnLayouts.LookupMode := true;
                                    if ColumnLayouts.RunModal() = ACTION::LookupOK then begin
                                        ColumnLayouts.GetRecord(ColumnLayout);
                                        Rec."Internal Source Column No." := ColumnLayout."Line No.";
                                        Rec."Int. Source Column Header" := ColumnLayout."Column Header";
                                    end;
                                end;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnInit()
    begin
        "Int. Source Section CodeEnable" := true;
        IntSourceColumnHeaderEnable := true;
    end;

    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        TaxRegisterTemplate: Record "Tax Register Template";
        TaxCalcLine: Record "Tax Calc. Line";
        AccScheduleLines: Page "Acc. Schedule Lines";
        ColumnLayouts: Page "Column Layouts";
        TaxRegisterTemplateLines: Page "Tax Register Templates";
        TaxCalcLines: Page "Tax Calc. Lines";
        IntSourceColumnHeaderEnable: Boolean;
        "Int. Source Section CodeEnable": Boolean;

    [Scope('OnPrem')]
    procedure UpdateControls()
    var
        TaxReg: Boolean;
    begin
        TaxReg := Rec."Int. Source Type" in [Rec."Int. Source Type"::"Tax Register", Rec."Int. Source Type"::"Tax Difference"];
        "Int. Source Section CodeEnable" := TaxReg;
        IntSourceColumnHeaderEnable := not TaxReg;
    end;

    [Scope('OnPrem')]
    procedure SetData(StatReportTableMapping: Record "Stat. Report Table Mapping")
    begin
        Rec := StatReportTableMapping;
        Rec.Insert();
    end;

    local procedure IntSourceTypeOnAfterValidate()
    begin
        UpdateControls();
    end;
}

