#pragma warning disable AA0247
report 12495 "FA Inventory Card FA-6"
{
    Caption = 'FA Inventory Card FA-6';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.";
            dataitem("FA Depreciation Book"; "FA Depreciation Book")
            {
                DataItemLink = "FA No." = field("No.");
                DataItemTableView = sorting("FA No.", "Depreciation Book Code");
                dataitem(InitialAcquisition; "FA Ledger Entry")
                {
                    DataItemLink = "FA No." = field("FA No."), "Depreciation Book Code" = field("Depreciation Book Code");
                    DataItemTableView = sorting("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date", "Part of Book Value", "Reclassification Entry") where("FA Posting Type" = filter("Acquisition Cost"), "Initial Acquisition" = const(true), Quantity = filter(> 0));

                    trigger OnAfterGetRecord()
                    begin
                        TempFALedgerEntry := InitialAcquisition;
                        TempFALedgerEntry.Description := Format("FA Posting Type");
                        TempFALedgerEntry.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Posting Date", '<=%1', CreateDate);
                    end;
                }
                dataitem(Transfer; "FA Ledger Entry")
                {
                    DataItemLink = "FA No." = field("FA No."), "Depreciation Book Code" = field("Depreciation Book Code");
                    DataItemTableView = sorting("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date", "Part of Book Value", "Reclassification Entry") where("FA Posting Type" = filter("Acquisition Cost"), "Initial Acquisition" = const(false), Quantity = filter(> 0), "Reclassification Entry" = const(true));
                    PrintOnlyIfDetail = true;

                    trigger OnAfterGetRecord()
                    begin
                        TempFALedgerEntry := Transfer;
                        TempFALedgerEntry.Description := TransferOperationTypeTxt;
                        TempFALedgerEntry.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Posting Date", '<=%1', CreateDate);
                    end;
                }
                dataitem(WriteOff; "FA Ledger Entry")
                {
                    DataItemLink = "FA No." = field("FA No."), "Depreciation Book Code" = field("Depreciation Book Code");
                    DataItemTableView = sorting("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date", "Part of Book Value", "Reclassification Entry") where("FA Posting Type" = filter("Acquisition Cost"), "FA Posting Category" = filter(Disposal));

                    trigger OnAfterGetRecord()
                    begin
                        TempFALedgerEntry := WriteOff;
                        TempFALedgerEntry.Description := Format("FA Posting Category");
                        TempFALedgerEntry.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Posting Date", '<=%1', CreateDate);
                    end;
                }
                dataitem("Integer 1"; "Integer")
                {
                    DataItemTableView = sorting(Number);

                    trigger OnAfterGetRecord()
                    var
                        FADepreciationBook: Record "FA Depreciation Book";
                    begin
                        if Number = 1 then
                            TempFALedgerEntry.FindSet()
                        else
                            TempFALedgerEntry.Next();
                        FADepreciationBook.Get(TempFALedgerEntry."FA No.", TempFALedgerEntry."Depreciation Book Code");
                        FADepreciationBook.SetFilter("FA Posting Date Filter", '<=%1', TempFALedgerEntry."Posting Date");
                        FADepreciationBook.CalcFields("Acquisition Cost", Depreciation);
                        FillFirstPageBody(
                          TempFALedgerEntry."Document No." + ', ' + Format(TempFALedgerEntry."Posting Date"),
                          TempFALedgerEntry.Description, TempFALedgerEntry."FA Location Code",
                          FADepreciationBook."Acquisition Cost" + FADepreciationBook.Depreciation, TempFALedgerEntry."Employee No.");
                    end;

                    trigger OnPostDataItem()
                    begin
                        TempFALedgerEntry.DeleteAll();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TempFALedgerEntry.Reset();
                        SetRange(Number, 1, TempFALedgerEntry.Count);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    FAPostingGroup.Get("FA Posting Group");
                    "Initial Acquisition Filter" := true;
                    CalcFields("Acquisition Cost", Depreciation, "Initial Acquisition Cost", "Depreciated Cost");

                    InitialAcquisitionCost := 0;
                    if "Initial Acquisition Cost" = 0 then
                        InitialAcquisitionCost := "Acquisition Cost"
                    else
                        InitialAcquisitionCost := "Initial Acquisition Cost";

                    FillFirstPageHeader();
                end;

                trigger OnPostDataItem()
                begin
                    ExcelReportBuilderMgr.AddSection('FIRSTPAGEFOOTER');
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Depreciation Book Code", ForBook);
                end;
            }
            dataitem("FA Depreciation Book 2"; "FA Depreciation Book")
            {
                DataItemLink = "FA No." = field("No.");
                DataItemTableView = sorting("FA No.", "Depreciation Book Code");
                dataitem("FA Ledger Entry 2"; "FA Ledger Entry")
                {
                    DataItemLink = "FA No." = field("FA No."), "Depreciation Book Code" = field("Depreciation Book Code");
                    DataItemTableView = sorting("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date", "Part of Book Value", "Reclassification Entry") where("FA Posting Type" = filter("Acquisition Cost"), "Initial Acquisition" = const(false), Quantity = filter(> 0));

                    trigger OnAfterGetRecord()
                    begin
                        FALedgerEntry.Reset();
                        FALedgerEntry.SetRange("FA No.", "FA No.");
                        FALedgerEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
                        FALedgerEntry.SetRange("Initial Acquisition", false);
                        FALedgerEntry.SetFilter(Quantity, '<%1', 0);
                        if FALedgerEntry.FindFirst() then
                            CurrReport.Skip();

                        ExcelReportBuilderMgr.AddSection('LASTPAGEBODY');
                        ExcelReportBuilderMgr.AddDataToSection('a1_1', Format("FA Posting Type"));
                        ExcelReportBuilderMgr.AddDataToSection('a1_2', Description);
                        ExcelReportBuilderMgr.AddDataToSection('a1_3', Format("Posting Date"));
                        ExcelReportBuilderMgr.AddDataToSection('a1_4', "Document No.");
                        ExcelReportBuilderMgr.AddDataToSection('a1_5', StdRepMgt.FormatReportValue(Abs(Amount), 2));
                    end;
                }

                trigger OnPreDataItem()
                begin
                    SetRange("Depreciation Book Code", ForBook);

                    ExcelReportBuilderMgr.SetSheet('Sheet2');
                    ExcelReportBuilderMgr.AddSection('LASTPAGEHEADER');
                end;
            }
            dataitem("Integer 2"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;

                trigger OnAfterGetRecord()
                begin
                    ExcelReportBuilderMgr.AddSection('LASTPAGEHEADER7');
                end;
            }
            dataitem("Main Asset Component"; "Main Asset Component")
            {
                DataItemLink = "Main Asset No." = field("No.");
                DataItemTableView = sorting("Main Asset No.", "FA No.");

                trigger OnAfterGetRecord()
                begin
                    ExcelReportBuilderMgr.AddSection('LASTPAGEBODY7');
                    ExcelReportBuilderMgr.AddDataToSection('p1_1', Description);
                    ExcelReportBuilderMgr.AddDataToSection('p1_2', Format(Quantity));
                end;
            }
            dataitem("Item/FA Precious Metal"; "Item/FA Precious Metal")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("Item Type", "No.", "Precious Metals Code") where("Item Type" = const(FA));

                trigger OnAfterGetRecord()
                begin
                    ExcelReportBuilderMgr.AddSection('LASTPAGEBODY7');
                    ExcelReportBuilderMgr.AddDataToSection('z1_3', Name);
                    ExcelReportBuilderMgr.AddDataToSection('z1_4', "Nomenclature No.");
                    ExcelReportBuilderMgr.AddDataToSection('z1_5', "Unit of Measure Code");
                    ExcelReportBuilderMgr.AddDataToSection('z1_6', Format(Quantity));
                    ExcelReportBuilderMgr.AddDataToSection('z1_7', Format(Mass));
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;

                trigger OnAfterGetRecord()
                begin
                    ExcelReportBuilderMgr.AddSection('LASTPAGEFOOTER');
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FASetup.Get();
                if FASetup."FA Location Mandatory" then
                    TestField("FA Location Code");
                if FASetup."Employee No. Mandatory" then
                    TestField("Responsible Employee");

                FactYears := LocMgt.GetPeriodDate("Initial Release Date", CreateDate, 2);

                PostedFADocLine.Reset();
                PostedFADocLine.SetRange("Document Type", PostedFADocLine."Document Type"::Release);
                PostedFADocLine.SetRange("FA No.", "Fixed Asset"."No.");
                if PostedFADocLine.FindFirst() then;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CreateDate; CreateDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the creation date of the related document.';
                    }
                    field(ForBook; ForBook)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CreateDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        if CompanyInf.Get() then;
    end;

    trigger OnPostReport()
    begin
        if FileName <> '' then
            ExcelReportBuilderMgr.ExportDataToClientFile(FileName)
        else
            ExcelReportBuilderMgr.ExportData();
    end;

    trigger OnPreReport()
    begin
        FASetup.Get();
        FASetup.TestField("FA-6 Template Code");
        ExcelReportBuilderMgr.InitTemplate(FASetup."FA-6 Template Code");
        ExcelReportBuilderMgr.SetSheet('Sheet1');
    end;

    var
        CompanyInf: Record "Company Information";
        FASetup: Record "FA Setup";
        FAPostingGroup: Record "FA Posting Group";
        FALedgerEntry: Record "FA Ledger Entry";
        PostedFADocLine: Record "Posted FA Doc. Line";
        TempFALedgerEntry: Record "FA Ledger Entry" temporary;
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        CreateDate: Date;
        ForBook: Code[10];
        FactYears: Text[30];
        FileName: Text;
        InitialAcquisitionCost: Decimal;
        TransferOperationTypeTxt: Label 'Transfer';

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewCreateDate: Date; NewForBook: Code[10])
    begin
        CreateDate := NewCreateDate;
        ForBook := NewForBook;
    end;

    local procedure FillFirstPageHeader()
    var
        FALocation: Record "FA Location";
    begin
        ExcelReportBuilderMgr.AddSection('FIRSTPAGEHEADER');
        ExcelReportBuilderMgr.AddDataToSection('CompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderMgr.AddDataToSection('DocumentNum', "Fixed Asset"."No.");
        ExcelReportBuilderMgr.AddDataToSection('DocumentDate', Format(CreateDate));
        ExcelReportBuilderMgr.AddDataToSection('AssetName', "Fixed Asset".Description + "Fixed Asset"."Description 2");
        ExcelReportBuilderMgr.AddDataToSection('OKPO', CompanyInf."OKPO Code");
        ExcelReportBuilderMgr.AddDataToSection('OKOF', "Fixed Asset"."Depreciation Code");
        ExcelReportBuilderMgr.AddDataToSection('DeprGroupName', "Fixed Asset"."Depreciation Group");
        ExcelReportBuilderMgr.AddDataToSection('PassportNum', "Fixed Asset"."Passport No.");
        ExcelReportBuilderMgr.AddDataToSection('FactoryNumber', "Fixed Asset"."Factory No.");
        ExcelReportBuilderMgr.AddDataToSection('InventoryNumber', "Fixed Asset"."Inventory Number");
        ExcelReportBuilderMgr.AddDataToSection('AcquisitionDate', Format("Fixed Asset"."Initial Release Date"));
        ExcelReportBuilderMgr.AddDataToSection('DisposalDate', Format("Fixed Asset"."Vehicle Writeoff Date"));
        ExcelReportBuilderMgr.AddDataToSection('Account', FAPostingGroup."Acquisition Cost Account");
        if FALocation.Get("Fixed Asset"."FA Location Code") then begin
            ExcelReportBuilderMgr.AddDataToSection('AssetLocation', FALocation.Name);
            ExcelReportBuilderMgr.AddDataToSection('DepartmentName', FALocation.Name);
        end;
        ExcelReportBuilderMgr.AddDataToSection('AssetMade', "Fixed Asset".Manufacturer);
        if "Fixed Asset"."Accrued Depr. Amount" <> 0 then begin
            ExcelReportBuilderMgr.AddDataToSection('d1_1', Format("Fixed Asset"."Manufacturing Year"));
            ExcelReportBuilderMgr.AddDataToSection('d1_3', Format(PostedFADocLine."Document Type"));
            ExcelReportBuilderMgr.AddDataToSection('d1_4', PostedFADocLine."Document No.");
            ExcelReportBuilderMgr.AddDataToSection('d1_5', Format(PostedFADocLine."Posting Date"));
            ExcelReportBuilderMgr.AddDataToSection('d1_6', FactYears);
            ExcelReportBuilderMgr.AddDataToSection('d1_7', StdRepMgt.FormatReportValue(Abs("FA Depreciation Book".Depreciation), 2));
            ExcelReportBuilderMgr.AddDataToSection('d1_8', StdRepMgt.FormatReportValue(Abs("FA Depreciation Book"."Depreciated Cost"), 2));
        end;
        ExcelReportBuilderMgr.AddDataToSection('d1_9', StdRepMgt.FormatReportValue(InitialAcquisitionCost, 2));
        ExcelReportBuilderMgr.AddDataToSection('d1_10', Format("FA Depreciation Book"."No. of Depreciation Years"));
    end;

    local procedure FillFirstPageBody(DocumentNoDate: Text; OperationType: Text; FALocation: Text; BookValue: Decimal; ResponsiblePerson: Code[20])
    begin
        ExcelReportBuilderMgr.AddSection('FIRSTPAGEBODY');
        ExcelReportBuilderMgr.AddDataToSection('b1_1', DocumentNoDate);
        ExcelReportBuilderMgr.AddDataToSection('b1_2', OperationType);
        ExcelReportBuilderMgr.AddDataToSection('b1_3', FALocation);
        ExcelReportBuilderMgr.AddDataToSection('b1_4', StdRepMgt.FormatReportValue(BookValue, 2));
        ExcelReportBuilderMgr.AddDataToSection('b1_5', StdRepMgt.GetEmpName(ResponsiblePerson));
    end;
}

