// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Reflection;

table 477 "Report Inbox"
{
    Caption = 'Report Inbox';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "User ID"; Text[65])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(3; "Report Output"; BLOB)
        {
            Caption = 'Report Output';
        }
        field(4; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
            Editable = false;
        }
        field(5; "Job Queue Log Entry ID"; Guid)
        {
            Caption = 'Job Queue Log Entry ID';
            Editable = false;
        }
        field(6; "Output Type"; Enum "Report Inbox Output Type")
        {
            Caption = 'Output Type';
            Editable = false;
        }
        field(7; Description; Text[250])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(8; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            Editable = false;
        }
        field(9; "Report Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Report ID")));
            Caption = 'Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; Read; Boolean)
        {
            Caption = 'Read';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "User ID", "Created Date-Time")
        {
        }
    }

    fieldgroups
    {
    }

    var
        FileDownLoadTxt: Label 'Export';
        ReportIsEmptyMsg: Label 'The report is empty.';
        NoReportsToShowErr: Label 'There are no reports in the list.';
        FileDoesNotExistErr: Label 'The file does not exist.';

    procedure ShowReport()
    var
        Instr: InStream;
        Downloaded: Boolean;
        FileName: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReport(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Entry No." = 0 then
            Error(NoReportsToShowErr);

        CalcFields("Report Output", "Report Name");
        if not "Report Output".HasValue() then begin
            Read := true;
            Modify();
            Commit();
            Message(ReportIsEmptyMsg);
            exit;
        end;
        FileName := GetFileNameWithExtension();

        "Report Output".CreateInStream(Instr);
        Downloaded := DownloadFromStream(Instr, FileDownLoadTxt, '', '', FileName);

        if not Read and Downloaded then begin
            Read := true;
            Modify();
        end;
    end;

    procedure Suffix() Result: Text
    begin
        case "Output Type" of
            "Output Type"::PDF:
                exit('.pdf');
            "Output Type"::Word:
                exit('.docx');
            "Output Type"::Excel:
                exit('.xlsx');
            "Output Type"::Zip:
                exit('.zip');
            else
                OnSuffixCaseElse(Rec, Result);
        end;
    end;

    procedure GetFileNameWithExtension(): Text
    begin
        exit(GetFileNameWithoutExtension() + Suffix());
    end;

    procedure GetFileNameWithoutExtension(): Text
    var
        FileName: Text;
    begin
        if "Report Name" <> '' then
            FileName := DelChr("Report Name", '=', '/:*?"<>|')
        else
            FileName := DelChr(Description, '=', '/:*?"<>|');

        exit(FileName);
    end;

    procedure OpenInOneDrive()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
        FileName: Text;
        FileExtension: Text;
        InStream: InStream;
    begin
        if "Report Name" = '' then
            Error(FileDoesNotExistErr);

        CalcFields("Report Output");
        "Report Output".CreateInStream(InStream);
        FileName := GetFileNameWithoutExtension();
        FileExtension := Suffix();
        DocumentServiceMgt.OpenInOneDrive(FileName, FileExtension, InStream);
    end;

    procedure ShareWithOneDrive()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
        FileName: Text;
        FileExtension: Text;
        InStream: InStream;
    begin
        if "Report Name" = '' then
            Error(FileDoesNotExistErr);

        CalcFields("Report Output");
        "Report Output".CreateInStream(InStream);
        FileName := GetFileNameWithoutExtension();
        FileExtension := Suffix();
        DocumentServiceMgt.ShareWithOneDrive(FileName, FileExtension, InStream);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReport(var ReportInbox: Record "Report Inbox"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSuffixCaseElse(ReportInbox: Record "Report Inbox"; var Result: Text)
    begin
    end;
}

