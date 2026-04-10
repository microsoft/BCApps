#pragma warning disable AA0247
report 17208 "Tax Register"
{
    Caption = 'Tax Register';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Tax Register"; "Tax Register")
        {
            DataItemTableView = sorting("Section Code", "No.");
            RequestFilterFields = "No.", "Date Filter";
            dataitem("Tax Register Accumulation"; "Tax Register Accumulation")
            {
                DataItemLink = "Section Code" = field("Section Code"), "Tax Register No." = field("No."), "Date Filter" = field("Date Filter");
                DataItemTableView = sorting("Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date");

                trigger OnAfterGetRecord()
                begin
                    Counter += 1;
                    ExcelReportBuilderManager.SetSheet('Sheet1');
                    if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('BODY', 'REPORTFOOTER') then begin
                        ExcelReportBuilderManager.AddPagebreak();
                        ExcelReportBuilderManager.AddSection('PAGEHEADER');
                        ExcelReportBuilderManager.AddSection('BODY');
                    end;
                    ExcelReportBuilderManager.AddDataToSection('Number', Format(Counter));
                    ExcelReportBuilderManager.AddDataToSection('Description', Description);
                    ExcelReportBuilderManager.AddDataToSection('Amount', StdRepMgt.FormatReportValue(Amount, 2));
                    TotalAmount += Amount;
                end;

                trigger OnPreDataItem()
                begin
                    ExcelReportBuilderManager.SetSheet('Sheet1');
                    ExcelReportBuilderManager.AddSection('PAGEHEADER');
                end;
            }
            dataitem("Integer"; "Integer")
            {
                MaxIteration = 1;

                trigger OnAfterGetRecord()
                var
                    TaxRegGLEntry: Record "Tax Register G/L Entry";
                    TaxRegCVEntry: Record "Tax Register CV Entry";
                    TaxRegItemEntry: Record "Tax Register Item Entry";
                    TaxRegFAEntry: Record "Tax Register FA Entry";
                    TaxRegFEEntry: Record "Tax Register FE Entry";
                    TaxRegAccumulation: Record "Tax Register Accumulation";
                    "Field": Record "Field";
                    RecRef: RecordRef;
                    FldRef: FieldRef;
                    j: Integer;
                begin
                    RecRef.Open("Tax Register"."Table ID");

                    // Print columns
                    j := 1;
                    ExcelReportBuilderManager.AddSection('BODYDETAIL');
                    Field.SetRange(Class, Field.Class::Normal);
                    Field.SetRange(TableNo, RecRef.Number);
                    Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
                    if Field.FindSet() then
                        repeat
                            FldRef := RecRef.Field(Field."No.");
                            ExcelReportBuilderManager.AddDataToSection('Field' + Format(j), FldRef.Caption);
                            j += 1;
                        until Field.Next() = 0;

                    case "Tax Register"."Table ID" of
                        DATABASE::"Tax Register G/L Entry":
                            FldRef := RecRef.Field(TaxRegGLEntry.FieldNo("Ending Date"));
                        DATABASE::"Tax Register CV Entry":
                            FldRef := RecRef.Field(TaxRegCVEntry.FieldNo("Ending Date"));
                        DATABASE::"Tax Register Item Entry":
                            FldRef := RecRef.Field(TaxRegItemEntry.FieldNo("Ending Date"));
                        DATABASE::"Tax Register FA Entry":
                            FldRef := RecRef.Field(TaxRegFAEntry.FieldNo("Ending Date"));
                        DATABASE::"Tax Register FE Entry":
                            FldRef := RecRef.Field(TaxRegFEEntry.FieldNo("Ending Date"));
                        DATABASE::"Tax Register Accumulation":
                            FldRef := RecRef.Field(TaxRegAccumulation.FieldNo("Ending Date"));
                    end;
                    FldRef.SetFilter("Tax Register".GetFilter("Date Filter"));
                    if not RecRef.FindSet() then
                        exit;

                    // Print values
                    j := 1;
                    repeat
                        ExcelReportBuilderManager.AddSection('BODYDETAIL');
                        Field.SetRange(Class, Field.Class::Normal);
                        Field.SetRange(TableNo, RecRef.Number);
                        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
                        if Field.FindSet() then
                            repeat
                                FldRef := RecRef.Field(Field."No.");
                                ExcelReportBuilderManager.AddDataToSection('Field' + Format(j), Format(FldRef.Value));
                                j += 1;
                            until Field.Next() = 0;
                    until RecRef.Next() = 0;
                end;

                trigger OnPreDataItem()
                begin
                    if not PrintDetails then
                        CurrReport.Break();

                    ExcelReportBuilderManager.SetSheet('Sheet2');
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ExcelReportBuilderManager.AddSection('REPORTHEADER');
                ExcelReportBuilderManager.AddDataToSection('CompanyName', StdRepMgt.GetCompanyName());
                ExcelReportBuilderManager.AddDataToSection('UserID', UserId);
                ExcelReportBuilderManager.AddDataToSection('CreationDate', Format(CurrentDateTime));
                ExcelReportBuilderManager.AddDataToSection('RegisterName', Description);
                ExcelReportBuilderManager.AddDataToSection('PeriodFilter', Format(GetFilter("Date Filter")));
                TotalAmount := 0;
            end;

            trigger OnPostDataItem()
            begin
                ExcelReportBuilderManager.SetSheet('Sheet1');
                ExcelReportBuilderManager.AddSection('REPORTFOOTER');
                ExcelReportBuilderManager.AddDataToSection('Total', StdRepMgt.FormatReportValue(TotalAmount, 2));
            end;

            trigger OnPreDataItem()
            var
                TaxRegisterSetup: Record "Tax Register Setup";
            begin
                TaxRegisterSetup.Get();
                TaxRegisterSetup.TestField("Tax Register Template Code");
                ExcelReportBuilderManager.InitTemplate(TaxRegisterSetup."Tax Register Template Code");
                ExcelReportBuilderManager.SetSheet('Sheet1');
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field("Print Details"; PrintDetails)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileName = '' then
            ExcelReportBuilderManager.ExportData()
        else
            ExcelReportBuilderManager.ExportDataToClientFile(FileName);
    end;

    var
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";
        PrintDetails: Boolean;
        TotalAmount: Decimal;
        Counter: Integer;
        FileName: Text;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewPrintDetails: Boolean)
    begin
        PrintDetails := NewPrintDetails;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

