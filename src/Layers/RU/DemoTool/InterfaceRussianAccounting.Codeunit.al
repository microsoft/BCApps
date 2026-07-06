codeunit 163400 "Interface Russian Accounting"
{

    trigger OnRun()
    begin
        CreateDemoData();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;
        XADJ0003: Label 'ADJ0003';

    procedure CreateDemoData()
    begin
        DemoDataSetup.Get();

        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, 'Russian Accounting');

        Steps := 0;
        MaxSteps := 7; // Numer of calls to RunCodeunit

        RunCodeunit(CODEUNIT::"Create Stat. Reporting Setup");
        RunCodeunit(CODEUNIT::"Create Depreciation Group");
        RunCodeunit(CODEUNIT::"Create Payment Codes");
        if not DemoDataSetup."Skip sequence of actions" then begin
            RunCodeunit(CODEUNIT::"Create Item Documents");
            RunCodeunit(CODEUNIT::"Create FA Documents");
        end;

        // Import data
        // InterfaceBasisData.ImportDataByXMLPort(XMLPORT::OKATO,'RUS_OKATO.xml');
        // InterfaceBasisData.ImportDataByXMLPort(XMLPORT::KBK,'RUS_KBK.xml');
        // InterfaceBasisData.ImportDataByXMLPort(XMLPORT::"BIC Directory",'RUS_BIC.xml');
        // InterfaceBasisData.ImportDataByXMLPort(XMLPORT::OKOF,'RUS_OKOF.xml');

        Window.Close();
    end;

    procedure "Before Posting"()
    begin
    end;

    procedure Post(PostingDate: Date)
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, 'Russian Accounting');
        Steps := 0;
        MaxSteps := 0;

        Window.Close();
    end;

    procedure "After Posting"()
    var
        StatReport: Record "Statutory Report";
        FormatVersion: Record "Format Version";
        AccSchName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        PostInvCostToGL: Report "Post Inventory Cost to G/L";
        Translate: Codeunit "Translate Accounting";
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, 'RU Specific');
        Steps := 0;
        MaxSteps := 9;

        if GlobalLanguage <> 1033 then begin // Test E-Rep data translation
            Clear(Translate);
            Translate.SetTestMode(true);

            StatReport.Reset();
            if StatReport.FindSet() then
                repeat
                    if Translate.ReportCode(StatReport.Code) = StatReport.FieldName(Code) then
                        Error('Missing translation for %1 %2 %3', StatReport.TableName, StatReport.FieldName(Code), StatReport.Code);
                until StatReport.Next() = 0;

            FormatVersion.Reset();
            if FormatVersion.FindSet() then
                repeat
                    if Translate.ReportCode(FormatVersion.Code) = FormatVersion.FieldName(Code) then
                        Error('Missing translation for %1 %2 %3', FormatVersion.TableName, FormatVersion.FieldName(Code), FormatVersion.Code);
                until FormatVersion.Next() = 0;

            AccSchName.Reset();
            if AccSchName.FindSet() then
                repeat
                    if Translate.ReportCode(AccSchName.Name) = AccSchName.FieldName(Name) then
                        Error('Missing translation for %1 %2 %3', AccSchName.TableName, AccSchName.FieldName(Name), AccSchName.Name);
                until AccSchName.Next() = 0;

            ColumnLayoutName.Reset();
            if ColumnLayoutName.FindSet() then
                repeat
                    if Translate.ReportCode(ColumnLayoutName.Name) = ColumnLayoutName.FieldName(Name) then
                        Error('Missing translation for %1 %2 %3', ColumnLayoutName.TableName, ColumnLayoutName.FieldName(Name), ColumnLayoutName.Name);
                until ColumnLayoutName.Next() = 0;
        end;

        if not DemoDataSetup."Skip sequence of actions" then begin
            RunCodeunit(CODEUNIT::"Create Bank Orders");
            RunCodeunit(CODEUNIT::"Create CD and Employee Adv.");
            RunCodeunit(CODEUNIT::"Create VAT Purchase Ledgers");
            RunCodeunit(CODEUNIT::"Create VAT Sales Ledgers");

            Clear(PostInvCostToGL);
            PostInvCostToGL.InitializeRequest(0, XADJ0003, true);
            PostInvCostToGL.UseRequestPage(false);
            //if DemoDataSetup."Path to Print Files (HTML)" = '' then
            //    PostInvCostToGL.RunModal()
            //else
            PostInvCostToGL.SaveAsPdf('PostInvCost.pdf');
        end;

        Window.Close();
    end;

    procedure RunCodeunit(CodeunitID: Integer)
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, CodeunitID);
        Window.Update(1, StrSubstNo('%1 %2', AllObj."Object ID", AllObj."Object Name"));
        Steps := Steps + 1;
        Window.Update(2, Round(Steps / MaxSteps * 10000, 1));
        CODEUNIT.Run(CodeunitID);
    end;

    procedure "Finalize Setup"()
    var
        AccSchedule: Record "Acc. Schedule Name";
        TempAccSchedule: Record "Acc. Schedule Name" temporary;
        StatReport: Record "Statutory Report";
        TempStatReport: Record "Statutory Report" temporary;
        StatReportTable: Record "Statutory Report Table";
        StatReportTableMapping: Record "Stat. Report Table Mapping";
        FormatVersion: Record "Format Version";
        TempFormatVersion: Record "Format Version" temporary;
        ColumnLayoutName: Record "Column Layout Name";
        TempColumnLayoutName: Record "Column Layout Name" temporary;
        ColumnLayout: Record "Column Layout";
        AccSchExtension: Record "Acc. Schedule Extension";
        StatReports: Page "Statutory Reports";
        Translate: Codeunit "Translate Accounting";
        Language: Codeunit Language;
        StatutoryReportMgt: Codeunit "Statutory Report Management";
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Import Electronic Reporting" and
           (not DemoDataSetup."Skip sequence of actions") and
           (not DemoDataSetup."Skip creation of master data")
        then begin
            if DemoDataSetup."Language Code" = 'RUS' then
                GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            Clear(StatReports);
            StatutoryReportMgt.ImportReportSettings('LocalFiles\ENU_StatReport.xml');
            Clear(AccSchedule);
            AccSchedule.ImportSettings('LocalFiles\ENU_AccSchedule.xml');

            if DemoDataSetup."Language Code" = 'RUS' then begin
                GlobalLanguage(1049);
                FormatVersion.Reset();
                if FormatVersion.FindSet() then
                    repeat
                        TempFormatVersion.Init();
                        TempFormatVersion := FormatVersion;
                        TempFormatVersion.Insert();
                    until FormatVersion.Next() = 0;
                TempFormatVersion.Reset();
                if TempFormatVersion.FindSet() then
                    repeat
                        FormatVersion.Get(TempFormatVersion.Code);
                        FormatVersion.Rename(Translate.ReportCode(TempFormatVersion.Code));
                    until TempFormatVersion.Next() = 0;
                TempFormatVersion.DeleteAll();

                StatReport.Reset();
                if StatReport.FindSet() then
                    repeat
                        TempStatReport.Init();
                        TempStatReport := StatReport;
                        TempStatReport.Insert();
                    until StatReport.Next() = 0;
                TempStatReport.Reset();
                if TempStatReport.FindSet() then
                    repeat
                        StatReport.Get(TempStatReport.Code);
                        case StatReport."Sender No." of
                            'AH':
                                StatReport."Sender No." := 'äÅ';
                            'JR':
                                StatReport."Sender No." := 'éè';
                            'MD':
                                StatReport."Sender No." := 'îæ';
                        end;
                        StatReport.Modify();
                        StatReport.Rename(CopyStr(Translate.ReportCode(TempStatReport.Code), 1, MaxStrLen(TempStatReport.Code)));
                    until TempStatReport.Next() = 0;
                TempStatReport.DeleteAll();

                AccSchedule.Reset();
                if AccSchedule.FindSet() then
                    repeat
                        TempAccSchedule.Init();
                        TempAccSchedule := AccSchedule;
                        TempAccSchedule.Insert();
                    until AccSchedule.Next() = 0;
                TempAccSchedule.Reset();
                if TempAccSchedule.FindSet() then
                    repeat
                        AccSchedule.Get(TempAccSchedule.Name);
                        AccSchedule."Analysis View Name" :=
                          Translate.ReportCode(TempAccSchedule."Analysis View Name");
                        AccSchedule.Modify();
                        AccSchedule.Rename(Translate.ReportCode(TempAccSchedule.Name));
                    until TempAccSchedule.Next() = 0;
                TempAccSchedule.DeleteAll();

                ColumnLayoutName.Reset();
                if ColumnLayoutName.FindSet() then
                    repeat
                        TempColumnLayoutName.Init();
                        TempColumnLayoutName := ColumnLayoutName;
                        TempColumnLayoutName.Insert();
                    until ColumnLayoutName.Next() = 0;
                TempColumnLayoutName.Reset();
                if TempColumnLayoutName.FindSet() then
                    repeat
                        ColumnLayoutName.Get(TempColumnLayoutName.Name);
                        ColumnLayoutName.Rename(Translate.ReportCode(TempColumnLayoutName.Name));
                    until TempColumnLayoutName.Next() = 0;
                TempColumnLayoutName.DeleteAll();

                if ColumnLayout.FindSet() then
                    repeat
                        if ColumnLayout.Formula <> '' then begin
                            ColumnLayout.Formula := Translate.GroupFilter(ColumnLayout.Formula);
                            ColumnLayout.Modify();
                        end;
                    until ColumnLayout.Next() = 0;

                StatReportTable.Reset();
                if StatReportTable.FindSet() then
                    repeat
                        if StatReportTable."Int. Source Section Code" <> '' then begin
                            StatReportTable."Int. Source Section Code" :=
                              Translate.ReportCode(StatReportTable."Int. Source Section Code");
                            StatReportTable.Modify();
                        end;
                        if StatReportTable."Int. Source No." <> '' then begin
                            StatReportTable."Int. Source No." :=
                              Translate.ReportCode(StatReportTable."Int. Source No.");
                            StatReportTable.Modify();
                        end;
                    until StatReportTable.Next() = 0;

                StatReportTableMapping.Reset();
                if StatReportTableMapping.FindSet() then
                    repeat
                        if StatReportTableMapping."Int. Source Section Code" <> '' then begin
                            StatReportTableMapping."Int. Source Section Code" :=
                              Translate.ReportCode(StatReportTableMapping."Int. Source Section Code");
                            StatReportTableMapping.Modify();
                        end;
                        if StatReportTableMapping."Int. Source No." <> '' then begin
                            StatReportTableMapping."Int. Source No." :=
                              Translate.ReportCode(StatReportTableMapping."Int. Source No.");
                            StatReportTableMapping.Modify();
                        end;
                    until StatReportTableMapping.Next() = 0;

                AccSchExtension.Reset();
                if AccSchExtension.FindSet() then
                    repeat
                        if AccSchExtension."VAT Bus. Post. Group Filter" <> '' then begin
                            AccSchExtension."VAT Bus. Post. Group Filter" :=
                              Translate.GroupFilter(AccSchExtension."VAT Bus. Post. Group Filter");
                            AccSchExtension.Modify();
                        end;
                        if AccSchExtension."VAT Prod. Post. Group Filter" <> '' then begin
                            AccSchExtension."VAT Prod. Post. Group Filter" :=
                              Translate.GroupFilter(AccSchExtension."VAT Prod. Post. Group Filter");
                            AccSchExtension.Modify();
                        end;
                    until AccSchExtension.Next() = 0;
            end;
        end;
    end;
}

