#pragma warning disable AA0247
report 14983 "Posted Sales FA Release FA-1"
{
    Caption = 'Posted Sales FA Release FA-1';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            dataitem("Sales Invoice Line"; "Sales Invoice Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.") where(Type = const("Fixed Asset"));
                dataitem("FA Depreciation Book"; "FA Depreciation Book")
                {
                    DataItemLink = "FA No." = field("No."), "Depreciation Book Code" = field("Depreciation Book Code");
                    DataItemTableView = sorting("FA No.", "Depreciation Book Code");

                    trigger OnAfterGetRecord()
                    begin
                        ActualUse := FA1Helper.CalcActualUse("Sales Invoice Header"."Posting Date", FA."Initial Release Date");

                        CalcFields("Acquisition Cost", Depreciation, "Proceeds on Disposal", "Initial Acquisition Cost");
                        if "No. of Depreciation Months" = 0 then
                            "No. of Depreciation Months" := "No. of Depreciation Years" * 12;

                        FA1Helper.FillDataLine(
                          FA."Manufacturing Year", Format(FA."Initial Release Date"), Format("Last Maintenance Date"), ActualUse,
                          Format("No. of Depreciation Months"), Depreciation, "Book Value", "Acquisition Cost", Format("Initial Acquisition Cost"),
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
                    TempPostFADocLine: Record "Posted FA Doc. Line";
                    OrgInfoArray: array[9] of Text;
                begin
                    FA.Get("No.");
                    TestField("Depreciation Book Code");
                    TestField("Posting Group");

                    FADepreciationBook.Get("No.", "Depreciation Book Code");
                    FAPostingGroup.Get(FADepreciationBook."FA Posting Group");

                    TempPostFADocLine."Document No." := "Document No.";
                    TempPostFADocLine."Document Type" := PostedFAComment."Document Type"::"Sales Invoice";
                    TempPostFADocLine.GetFAComments(Characteristics, PostedFAComment.Type::Characteristics);
                    TempPostFADocLine.GetFAComments(ExtraWork, PostedFAComment.Type::"Extra Work");
                    TempPostFADocLine.GetFAComments(Conclusion, PostedFAComment.Type::Conclusion);
                    TempPostFADocLine.GetFAComments(Appendix, PostedFAComment.Type::Appendix);
                    TempPostFADocLine.GetFAComments(Result, PostedFAComment.Type::Result);
                    TempPostFADocLine.GetFAComments(Reason, PostedFAComment.Type::Reason);

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
                          OrgInfoArray, "Sales Invoice Header"."No.",
                          Format("Sales Invoice Header"."Document Date"),
                          "Sales Invoice Header"."No.", Format("Sales Invoice Header"."Posting Date"), Format("Sales Invoice Header"."Posting Date"),
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

                CheckSignature(ReleasedBy, ReleasedBy."Employee Type"::ReleasedBy);
                CheckSignature(Chairman, Chairman."Employee Type"::Chairman);
                CheckSignature(Member1, Member1."Employee Type"::Member1);
                CheckSignature(Member2, Member2."Employee Type"::Member2);

                if LogInteraction then
                    if not CurrReport.Preview then
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Contact, "Bill-to Contact No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '')
                        else
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Customer, "Bill-to Customer No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '');

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
        PostedFAComment: Record "Posted FA Comment";
        ReleasedBy: Record "Posted Document Signature";
        Chairman: Record "Posted Document Signature";
        Member1: Record "Posted Document Signature";
        Member2: Record "Posted Document Signature";
        DocSignMgt: Codeunit "Doc. Signature Management";
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
        LogInteraction: Boolean;
        IsHeaderPrinted: Boolean;

    [Scope('OnPrem')]
    procedure CheckSignature(var PostedDocSign: Record "Posted Document Signature"; EmpType: Integer)
    begin
        DocSignMgt.GetPostedDocSign(
          PostedDocSign, DATABASE::"Sales Invoice Header",
          0, "Sales Invoice Header"."No.", EmpType, false);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

