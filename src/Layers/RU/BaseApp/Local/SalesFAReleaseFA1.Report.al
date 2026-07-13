#pragma warning disable AA0247
report 14982 "Sales FA Release FA-1"
{
    Caption = 'Sales FA Release FA-1';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = filter(Invoice));
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where(Type = const("Fixed Asset"));
                dataitem("FA Depreciation Book"; "FA Depreciation Book")
                {
                    DataItemLink = "FA No." = field("No."), "Depreciation Book Code" = field("Depreciation Book Code");
                    DataItemTableView = sorting("FA No.", "Depreciation Book Code");

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Acquisition Cost", Depreciation, "Depreciated Cost", "Initial Acquisition Cost");
                        ActualUse := FA1Helper.CalcActualUse("Sales Header"."Posting Date", FA."Initial Release Date");
                        NoOfDeprMonths := "No. of Depreciation Months";
                        if "No. of Depreciation Months" = 0 then
                            "No. of Depreciation Months" := "No. of Depreciation Years" * 12;

                        FA1Helper.FillDataLine(
                          FA."Manufacturing Year", Format(FA."Initial Release Date"), Format("Last Maintenance Date"), ActualUse,
                          Format(NoOfDeprMonths), Depreciation, "Book Value", "Acquisition Cost", Format("Initial Acquisition Cost"),
                          Format("No. of Depreciation Months"), Format("Depreciation Method"),
                          Format(FA1Helper.CalcDepreciationRate("FA Depreciation Book")), true);
                    end;

                    trigger OnPreDataItem()
                    begin
                        FA1Helper.SetBodySectionSheet();
                        FA1Helper.FillDataPageHeader();
                    end;
                }
                dataitem("Item/FA Precious Metal"; "Item/FA Precious Metal")
                {
                    DataItemLink = "No." = field("No.");
                    DataItemTableView = sorting("Item Type");

                    trigger OnAfterGetRecord()
                    begin
                        FA1Helper.FillCharLine(
                          Name, "Nomenclature No.", "Unit of Measure Code", Format(Quantity), Format(Mass));
                    end;

                    trigger OnPreDataItem()
                    begin
                        FA1Helper.FillCharPageHeader();
                    end;
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    MaxIteration = 1;

                    trigger OnAfterGetRecord()
                    begin
                        FA1Helper.SetFooterSectionSheet();
                        FA1Helper.FillReportFooter(
                          Result[1], Result[2], ExtraWork[1], ExtraWork[2], Conclusion[1], Conclusion[2], Appendix[1], Appendix[2],
                          Chairman."Employee Job Title", Chairman."Employee Name",
                          Member1."Employee Job Title", Member1."Employee Name",
                          Member2."Employee Job Title", Member2."Employee Name",
                          ReleasedBy."Employee Job Title", ReleasedBy."Employee Name",
                          '', '');
                    end;

                    trigger OnPreDataItem()
                    begin
                        FA1Helper.FillCharPageFooter(Characteristics);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    TempFADocLine: Record "FA Document Line";
                    OrgInfoArray: array[9] of Text;
                begin
                    FA.Get("No.");
                    TestField("Depreciation Book Code");
                    TestField("Posting Group");

                    FADepreciationBook.Get("No.", "Depreciation Book Code");
                    FAPostingGroup.Get(FADepreciationBook."FA Posting Group");

                    if "Sales Header"."Currency Code" = '' then
                        SaleAmount := "Line Amount"
                    else begin
                        "Sales Header".TestField("Currency Factor");
                        SaleAmount := Round("Line Amount" / "Sales Header"."Currency Factor");
                    end;

                    TempFADocLine."Document No." := "Document No.";
                    TempFADocLine."Document Type" := FAComment."Document Type"::"Sales Invoice";
                    TempFADocLine.GetFAComments(Characteristics, FAComment.Type::Characteristics);
                    TempFADocLine.GetFAComments(ExtraWork, FAComment.Type::"Extra Work");
                    TempFADocLine.GetFAComments(Conclusion, FAComment.Type::Conclusion);
                    TempFADocLine.GetFAComments(Appendix, FAComment.Type::Appendix);
                    TempFADocLine.GetFAComments(Result, FAComment.Type::Result);
                    TempFADocLine.GetFAComments(Reason, FAComment.Type::Reason);

                    if not IsHeaderPrinted then begin
                        OrgInfoArray[1] := ReceiverDirectorPosition;
                        OrgInfoArray[2] := ReceiverDirectorName;
                        OrgInfoArray[3] := DirectorPosition;
                        OrgInfoArray[4] := ReleasedBy."Employee Org. Unit";
                        OrgInfoArray[5] := ReceiverName;
                        OrgInfoArray[6] := ReceiverAddress;
                        OrgInfoArray[7] := ReceiverBank;
                        OrgInfoArray[8] := ReceiverDepartment;
                        OrgInfoArray[9] := Reason[1];

                        FA1Helper.FillHeader(
                          OrgInfoArray, "Sales Header"."No.",
                          Format("Sales Header"."Document Date"),
                          "Sales Header"."No.", Format("Sales Header"."Posting Date"), Format("Sales Header"."Posting Date"),
                          Format(FADepreciationBook."Disposal Date"), FAPostingGroup."Acquisition Cost Account", FA."Depreciation Code",
                          FA."Depreciation Group", FA."Inventory Number", FA."Factory No.",
                          FA."No." + ' ' + FA.Description + ' ' + FA."Description 2",
                          '', FA.Manufacturer, SupplementalInformation1, SupplementalInformation2);
                        IsHeaderPrinted := true;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    IsHeaderPrinted := false;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FASetup.Get();

                FA1Helper.CheckSignature(
                  ReleasedBy, DATABASE::"Sales Header", "Document Type".AsInteger(), "No.", ReleasedBy."Employee Type"::ReleasedBy);
                FA1Helper.CheckSignature(
                  Chairman, DATABASE::"Sales Header", "Document Type".AsInteger(), "No.", Chairman."Employee Type"::Chairman);
                FA1Helper.CheckSignature(
                  Member1, DATABASE::"Sales Header", "Document Type".AsInteger(), "No.", Member1."Employee Type"::Member1);
                FA1Helper.CheckSignature(
                  Member2, DATABASE::"Sales Header", "Document Type".AsInteger(), "No.", Member2."Employee Type"::Member2);

                if not CurrReport.Preview then begin
                    if ArchiveDocument then
                        ArchiveManagement.StoreSalesDocument("Sales Header", LogInteraction);

                    if LogInteraction then begin
                        CalcFields("No. of Archived Versions");
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              3, "No.", "Doc. No. Occurrence",
                              "No. of Archived Versions", DATABASE::Contact, "Bill-to Contact No."
                              , "Salesperson Code", "Campaign No.", "Posting Description", "Opportunity No.")
                        else
                            SegManagement.LogDocument(
                              3, "No.", "Doc. No. Occurrence",
                              "No. of Archived Versions", DATABASE::Customer, "Bill-to Customer No.",
                              "Salesperson Code", "Campaign No.", "Posting Description", "Opportunity No.");
                    end;
                end;

                FA1Helper.SetReportHeaderSheet();
            end;

            trigger OnPostDataItem()
            begin
                FA1Helper.SetReportHeaderSheet();
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
                    field(ReceiverDirectorPosition; ReceiverDirectorPosition)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Receiver Director Title';
                        ToolTip = 'Specifies the title of the director receiving the fixed asset.';
                    }
                    field(ReceiverDirectorName; ReceiverDirectorName)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Receiver Director Full Name';
                        ToolTip = 'Specifies the full name of the director receiving the fixed asset.';
                    }
                    field(ReceiverName; ReceiverName)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Receiver Organization';
                        ToolTip = 'Specifies the organizational unit.';
                    }
                    field(ReceiverAddress; ReceiverAddress)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Receiver Address';
                    }
                    field(ReceiverBank; ReceiverBank)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Receiver Bank Information';
                        ToolTip = 'Specifies the bank information of the organization receiving the fixed asset.';
                    }
                    field(ReceiverDepartment; ReceiverDepartment)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Receiver Org. Unit';
                        ToolTip = 'Specifies the organizational unit.';
                    }
                    field(SupplementalInformation1; SupplementalInformation1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Owners of shared property';
                        ToolTip = 'Specifies any shared owners of the related property.';
                    }
                    field(SupplementalInformation2; SupplementalInformation2)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Foreign currency';
                        ToolTip = 'Specifies the currency code for the transaction.';
                    }
                    field(ArchiveDocument; ArchiveDocument)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Save in Archive';
                        ToolTip = 'Specifies if you want to archive the related information. Archiving occurs when the report is printed.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Log Interaction';
                        ToolTip = 'Specifies that interactions with the related contact are logged.';
                    }
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

    trigger OnInitReport()
    var
        Employee: Record Employee;
    begin
        CompanyInfo.Get();
        if Employee.Get(CompanyInfo."Director No.") then
            DirectorPosition := Employee.GetJobTitleName();
    end;

    trigger OnPostReport()
    begin
        if FileName = '' then
            FA1Helper.ExportData()
        else
            FA1Helper.ExportDataFile(FileName);
    end;

    trigger OnPreReport()
    begin
        FA1Helper.InitReportTemplate();
    end;

    var
        FASetup: Record "FA Setup";
        CompanyInfo: Record "Company Information";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FA: Record "Fixed Asset";
        FAComment: Record "FA Comment";
        ReleasedBy: Record "Document Signature";
        Chairman: Record "Document Signature";
        Member1: Record "Document Signature";
        Member2: Record "Document Signature";
        DocSignMgt: Codeunit "Doc. Signature Management";
        ArchiveManagement: Codeunit ArchiveManagement;
        SegManagement: Codeunit SegManagement;
        FA1Helper: Codeunit "FA-1 Report Helper";
        Characteristics: array[5] of Text[80];
        ExtraWork: array[5] of Text[80];
        Conclusion: array[5] of Text[80];
        Appendix: array[5] of Text[80];
        Result: array[5] of Text[80];
        Reason: array[5] of Text[80];
        ActualUse: Text[30];
        ReceiverName: Text[100];
        ReceiverAddress: Text[100];
        ReceiverBank: Text[150];
        ReceiverDepartment: Text[100];
        ReceiverDirectorPosition: Text[100];
        ReceiverDirectorName: Text[100];
        SupplementalInformation1: Text[100];
        SupplementalInformation2: Text[100];
        DirectorPosition: Text[50];
        FileName: Text;
        ArchiveDocument: Boolean;
        LogInteraction: Boolean;
        SaleAmount: Decimal;
        NoOfDeprMonths: Decimal;
        IsHeaderPrinted: Boolean;

    [Scope('OnPrem')]
    procedure CheckSignature(var DocSign: Record "Document Signature"; EmpType: Integer)
    begin
        DocSignMgt.GetDocSign(
          DocSign, DATABASE::"Sales Header",
          "Sales Header"."Document Type".AsInteger(), "Sales Header"."No.", EmpType, true);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

