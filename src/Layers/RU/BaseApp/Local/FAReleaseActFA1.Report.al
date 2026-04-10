#pragma warning disable AA0247
report 12490 "FA Release Act FA-1"
{
    Caption = 'FA Release Act FA-1';
    ProcessingOnly = true;

    dataset
    {
        dataitem("FA Document Header"; "FA Document Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Release));
            RequestFilterFields = "No.";
            dataitem("FA Document Line"; "FA Document Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                RequestFilterFields = "Line No.";
                dataitem("FA Depreciation Book"; "FA Depreciation Book")
                {
                    CalcFields = "Initial Acquisition Cost", Depreciation, "Acquisition Cost";
                    DataItemLink = "FA No." = field("FA No."), "Depreciation Book Code" = field("Depreciation Book Code");
                    DataItemTableView = sorting("FA No.", "Depreciation Book Code");

                    trigger OnAfterGetRecord()
                    begin
                        ActualUse := FA1Helper.CalcActualUse("FA Document Header"."Posting Date", FA."Initial Release Date");

                        if NoOfDeprMonths = 0 then
                            NoOfDeprMonths := "No. of Depreciation Months";
                        if "No. of Depreciation Months" = 0 then
                            "No. of Depreciation Months" := "No. of Depreciation Years" * 12;

                        FA1Helper.FillDataLine(
                          FA."Manufacturing Year", Format(InitialReleaseDate), Format("Last Maintenance Date"), ActualUse,
                          Format(NoOfDeprMonths), Depreciation, "Book Value", "Acquisition Cost", Format("Initial Acquisition Cost"),
                          Format("No. of Depreciation Months"), Format("Depreciation Method"),
                          Format(FA1Helper.CalcDepreciationRate("FA Depreciation Book")), FA1Helper.IsPrintFADeprBookLine("FA Depreciation Book"));
                    end;

                    trigger OnPostDataItem()
                    begin
                        CalcFields("Initial Acquisition Cost", "Acquisition Cost", Depreciation);
                    end;

                    trigger OnPreDataItem()
                    begin
                        FA1Helper.SetBodySectionSheet();
                        FA1Helper.FillDataPageHeader();
                    end;
                }
                dataitem("Item/FA Precious Metal"; "Item/FA Precious Metal")
                {
                    DataItemLink = "No." = field("FA No.");
                    DataItemTableView = sorting("Item Type");

                    trigger OnAfterGetRecord()
                    begin
                        FA1Helper.FillCharLine(
                          Name, "Nomenclature No.", "Unit of Measure Code", Format(Quantity), Format(Mass));
                    end;

                    trigger OnPreDataItem()
                    begin
                        FA1Helper.FillCharPageHeader();
                        if IsHideOutput() then
                            CurrReport.Break();
                    end;
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    MaxIteration = 1;

                    trigger OnPreDataItem()
                    begin
                        FA1Helper.FillCharPageFooter(Characteristics);
                        if IsHideOutput() then
                            CurrReport.Break();

                        FA1Helper.SetFooterSectionSheet();
                        FA1Helper.FillReportFooter(
                          Result[1], Result[2], ExtraWork[1], ExtraWork[2], Conclusion[1], Conclusion[2], Appendix[1], Appendix[2],
                          Chairman."Employee Job Title", Chairman."Employee Name",
                          Member1."Employee Job Title", Member1."Employee Name",
                          Member2."Employee Job Title", Member2."Employee Name",
                          ReceivedBy."Employee Job Title", ReceivedBy."Employee Name",
                          StoredBy."Employee Job Title", StoredBy."Employee Name");
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    OrgInfoArray: array[9] of Text;
                begin
                    FA.Get("FA No.");
                    TestField("Depreciation Book Code");
                    TestField("FA Posting Group");

                    if FASetup."FA Location Mandatory" then
                        TestField("FA Location Code");

                    if "FA Location Code" <> '' then
                        FALocation.Get("FA Location Code");

                    if FA."Initial Release Date" <> 0D then
                        InitialReleaseDate := FA."Initial Release Date"
                    else
                        InitialReleaseDate := "FA Document Header"."Posting Date";

                    FADepreciationBook.Get("FA No.", "New Depreciation Book Code");
                    NoOfDeprMonths := FADepreciationBook."No. of Depreciation Months";
                    FAPostingGroup.Get(FADepreciationBook."FA Posting Group");

                    GetFAComments(Characteristics, FAComment.Type::Characteristics);
                    GetFAComments(ExtraWork, FAComment.Type::"Extra Work");
                    GetFAComments(Conclusion, FAComment.Type::Conclusion);
                    GetFAComments(Appendix, FAComment.Type::Appendix);
                    GetFAComments(Result, FAComment.Type::Result);
                    GetFAComments(Reason, FAComment.Type::Reason);

                    if not IsHeaderPrinted then begin
                        OrgInfoArray[1] := SenderDirectorPosition;
                        OrgInfoArray[2] := SenderDirectorName;
                        OrgInfoArray[3] := DirectorPosition;
                        OrgInfoArray[4] := ReceivedBy."Employee Org. Unit";
                        OrgInfoArray[5] := SenderName;
                        OrgInfoArray[6] := SenderAddress;
                        OrgInfoArray[7] := SenderBank;
                        OrgInfoArray[8] := SenderDepartment;
                        OrgInfoArray[9] := Reason[1];

                        FA1Helper.FillHeader(
                          OrgInfoArray, "FA Document Header"."Reason Document No.",
                          Format("FA Document Header"."Reason Document Date"),
                          DocumentNo, Format("FA Document Header"."Posting Date"), Format("FA Document Header"."FA Posting Date"),
                          Format(FADepreciationBook."Disposal Date"), FAPostingGroup."Acquisition Cost Account", FA."Depreciation Code",
                          FA."Depreciation Group", FA."Inventory Number", FA."Factory No.",
                          FA."No." + ' ' + FA.Description + ' ' + FA."Description 2",
                          FALocation.Name, FA.Manufacturer, SupplementalInformation1, SupplementalInformation2);
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
                  StoredBy, DATABASE::"FA Document Header", "Document Type", "No.", StoredBy."Employee Type"::StoredBy);
                FA1Helper.CheckSignature(
                  ReceivedBy, DATABASE::"FA Document Header", "Document Type", "No.", ReceivedBy."Employee Type"::ReceivedBy);
                FA1Helper.CheckSignature(
                  Chairman, DATABASE::"FA Document Header", "Document Type", "No.", Chairman."Employee Type"::Chairman);
                FA1Helper.CheckSignature(
                  Member1, DATABASE::"FA Document Header", "Document Type", "No.", Member1."Employee Type"::Member1);
                FA1Helper.CheckSignature(
                  Member2, DATABASE::"FA Document Header", "Document Type", "No.", Member2."Employee Type"::Member2);
                DocumentNo := "No.";

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
                    field(SenderDirectorPosition; SenderDirectorPosition)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Sender Director Title';
                        ToolTip = 'Specifies the title of the director who is releasing the fixed asset.';
                    }
                    field(SenderDirectorName; SenderDirectorName)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Sender Director Full Name';
                        ToolTip = 'Specifies the full name of the director who is releasing the fixed asset.';
                    }
                    field(SenderName; SenderName)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Sender Organization';
                        ToolTip = 'Specifies the name of the organization that is releasing the fixed asset.';
                    }
                    field(SenderAddress; SenderAddress)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Sender Address';
                        ToolTip = 'Specifies the address of the organization that is releasing the fixed asset.';
                    }
                    field(SenderBank; SenderBank)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Sender Bank Information';
                        ToolTip = 'Specifies the bank information of the organization that is releasing the fixed asset.';
                    }
                    field(SenderDepartment; SenderDepartment)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Sender Org. Unit';
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
        FASetup.Get();
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
        FALocation: Record "FA Location";
        FA: Record "Fixed Asset";
        FAComment: Record "FA Comment";
        ReceivedBy: Record "Document Signature";
        StoredBy: Record "Document Signature";
        Chairman: Record "Document Signature";
        Member1: Record "Document Signature";
        Member2: Record "Document Signature";
        FA1Helper: Codeunit "FA-1 Report Helper";
        Characteristics: array[5] of Text[80];
        ExtraWork: array[5] of Text[80];
        Conclusion: array[5] of Text[80];
        Appendix: array[5] of Text[80];
        Result: array[5] of Text[80];
        Reason: array[5] of Text[80];
        ActualUse: Text[30];
        SenderName: Text[100];
        SenderAddress: Text[100];
        SenderBank: Text[150];
        SenderDepartment: Text[100];
        SenderDirectorPosition: Text[100];
        SenderDirectorName: Text[100];
        SupplementalInformation1: Text[100];
        SupplementalInformation2: Text[100];
        DirectorPosition: Text[50];
        FileName: Text;
        DocumentNo: Code[20];
        InitialReleaseDate: Date;
        NoOfDeprMonths: Decimal;
        IsHeaderPrinted: Boolean;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure IsHideOutput(): Boolean
    begin
        exit(
          ("FA Document Header"."Document Type" = "FA Document Header"."Document Type"::Movement) or
          ("FA Document Header"."Document Type" = 3));
    end;
}

