#pragma warning disable AA0247
report 12476 "Item Card M-17"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item Card M-17';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Location Filter";
            dataitem("Item/FA Precious Metal"; "Item/FA Precious Metal")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("Item Type");

                trigger OnAfterGetRecord()
                begin
                    CalcFields(Name);

                    ExcelReportBuilderMgr.AddSection('PMETALBODY');
                    ExcelReportBuilderMgr.AddDataToSection('PMetalName', Name);
                    ExcelReportBuilderMgr.AddDataToSection('PMetalKind', Kind);
                    ExcelReportBuilderMgr.AddDataToSection('PMetalNo', "Nomenclature No.");
                    ExcelReportBuilderMgr.AddDataToSection('PMetalUnitCode', "Unit of Measure Code");
                    ExcelReportBuilderMgr.AddDataToSection('PMetalUnitID', StdRepMgt.GetUoMDesc("Unit of Measure Code"));
                    ExcelReportBuilderMgr.AddDataToSection('PMetalQty', Format(Quantity));
                    ExcelReportBuilderMgr.AddDataToSection('PMetalDocNo', "Document No.");
                end;
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter");
                DataItemTableView = sorting("Entry No.");

                trigger OnAfterGetRecord()
                begin
                    RecipientSender := '';

                    case "Source Type" of
                        "Source Type"::Vendor:
                            if Vend.Get("Source No.") then
                                RecipientSender := Vend.Name + Vend."Name 2";
                        "Source Type"::Customer:
                            if Cust.Get("Source No.") then
                                RecipientSender := Cust.Name + Cust."Name 2";
                        "Source Type"::Item:
                            if Location."Responsible Employee No." <> '' then
                                RecipientSender := StdRepMgt.GetEmpName(Location."Responsible Employee No.");
                    end;

                    if Quantity > 0 then begin
                        Income := Quantity;
                        Outcome := 0;
                    end else begin
                        Income := 0;
                        Outcome := -Quantity;
                    end;

                    if IsRedStorno() then begin
                        Quantity := Income;
                        Income := -Outcome;
                        Outcome := -Quantity;
                    end;

                    RemainingQty := RemainingQty + Income - Outcome;

                    if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('BODY', 'REPORTFOOTER') then begin
                        ExcelReportBuilderMgr.AddPagebreak();
                        ExcelReportBuilderMgr.AddSection('PAGEHEADER');
                        ExcelReportBuilderMgr.AddSection('BODY');
                    end;

                    ExcelReportBuilderMgr.AddDataToSection('DatePhysical', Format("Posting Date"));
                    ExcelReportBuilderMgr.AddDataToSection('DocumentNum', "Document No.");
                    ExcelReportBuilderMgr.AddDataToSection('TransCounter', Format("Entry No."));
                    ExcelReportBuilderMgr.AddDataToSection('Description', RecipientSender);
                    ExcelReportBuilderMgr.AddDataToSection('TransUnitId', "Unit of Measure Code");
                    ExcelReportBuilderMgr.AddDataToSection('ReceiptQty', Format(Income));
                    ExcelReportBuilderMgr.AddDataToSection('IssueQty', Format(Outcome));
                    ExcelReportBuilderMgr.AddDataToSection('Remainder', Format(RemainingQty));
                end;

                trigger OnPreDataItem()
                begin
                    RemainingQty := 0;

                    ExcelReportBuilderMgr.AddSection('PAGEHEADER');
                end;
            }
            dataitem(DocFooter; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnAfterGetRecord()
                begin
                    ExcelReportBuilderMgr.AddSection('REPORTFOOTER');
                    ExcelReportBuilderMgr.AddDataToSection('DayFooter', Format(WorkDate(), 0, '<Day,2>'));
                    ExcelReportBuilderMgr.AddDataToSection('MonthFooter', Format(LocMgt.Month2Text(WorkDate())));
                    ExcelReportBuilderMgr.AddDataToSection('YearFooter', Format(WorkDate(), 0, '<Year>'));
                    ExcelReportBuilderMgr.AddPagebreak();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ExcelReportBuilderMgr.AddSection('REPORTHEADER');
                ExcelReportBuilderMgr.AddDataToSection('ItemId', "No.");
                ExcelReportBuilderMgr.AddDataToSection('CompanyName', StdRepMgt.GetCompanyName());
                ExcelReportBuilderMgr.AddDataToSection('DepartmentName', Location.Name);
                ExcelReportBuilderMgr.AddDataToSection('OKPO', CompanyInfo."OKPO Code");
                ExcelReportBuilderMgr.AddDataToSection('DateOfCreation', Format(WorkDate()));

                ExcelReportBuilderMgr.AddDataToSection('OrgUnitName', StdRepMgt.GetEmpDepartment(Location."Responsible Employee No."));
                ExcelReportBuilderMgr.AddDataToSection('InventLocation', Location.Code);
                ExcelReportBuilderMgr.AddDataToSection('ShelfNo', "Shelf No.");
                ExcelReportBuilderMgr.AddDataToSection('UnitVolume', Format("Unit Volume"));
                ExcelReportBuilderMgr.AddDataToSection('InventoryNo', "No.");
                ExcelReportBuilderMgr.AddDataToSection('UnitCode', "Base Unit of Measure");
                ExcelReportBuilderMgr.AddDataToSection('UnitId', StdRepMgt.GetUoMDesc("Base Unit of Measure"));
                ExcelReportBuilderMgr.AddDataToSection('Price', Format("Unit Price"));
                ExcelReportBuilderMgr.AddDataToSection('Vendor', "Vendor No.");
                ExcelReportBuilderMgr.AddDataToSection('ItemName', Item.Description + Item."Description 2");
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                if GetFilter("Location Filter") <> '' then
                    Location.Get(GetFilter("Location Filter"));
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        if FileName <> '' then
            ExcelReportBuilderMgr.ExportDataToClientFile(FileName)
        else
            ExcelReportBuilderMgr.ExportData();
    end;

    trigger OnPreReport()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.TestField("Item Card M-17 Template Code");
        ExcelReportBuilderMgr.InitTemplate(InventorySetup."Item Card M-17 Template Code");
        ExcelReportBuilderMgr.SetSheet('Sheet1');
    end;

    var
        CompanyInfo: Record "Company Information";
        Location: Record Location;
        Vend: Record Vendor;
        Cust: Record Customer;
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        RecipientSender: Text[250];
        FileName: Text;
        RemainingQty: Decimal;
        Income: Decimal;
        Outcome: Decimal;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

