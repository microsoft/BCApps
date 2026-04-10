namespace System.Visualization;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Analysis;
using System.Reflection;

table 487 "Business Chart User Setup"
{
    Caption = 'Business Chart User Setup';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionCaption = ' ,Table,,Report,,Codeunit,XMLport,,Page';
            OptionMembers = " ","Table",,"Report",,"Codeunit","XMLport",,"Page";
        }
        field(3; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            TableRelation = if ("Object Type" = filter(> " ")) AllObj."Object ID" where("Object Type" = field("Object Type"));
        }
        field(4; "Period Length"; Option)
        {
            Caption = 'Period Length';
            OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period,None';
            OptionMembers = Day,Week,Month,Quarter,Year,"Accounting Period","None";
        }
    }

    keys
    {
        key(Key1; "User ID", "Object Type", "Object ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InitSetupPage(PageID: Integer)
    begin
        if Get(UserId, "Object Type"::Page, PageID) then
            exit;

        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Object Type" := "Object Type"::Page;
        "Object ID" := PageID;
        case "Object ID" of
            PAGE::"Aged Acc. Receivable Chart":
                "Period Length" := "Period Length"::Week;
        end;
        Insert();
    end;

    procedure InitSetupCU(CodeunitID: Integer)
    begin
        if Get(UserId, "Object Type"::Codeunit, CodeunitID) then
            exit;

        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Object Type" := "Object Type"::Codeunit;
        "Object ID" := CodeunitID;
        case "Object ID" of
            CODEUNIT::"Aged Acc. Receivable", CODEUNIT::"Aged Acc. Payable":
                "Period Length" := "Period Length"::Week;
        end;
        Insert();
    end;

    procedure SaveSetupPage(BusChartUserSetup: Record "Business Chart User Setup"; PageID: Integer)
    begin
        if not Get(UserId, "Object Type"::Page, PageID) then
            InitSetupPage(PageID);
        TransferFields(BusChartUserSetup, false);
        Modify();
    end;

    procedure SaveSetupCU(BusChartUserSetup: Record "Business Chart User Setup"; CodeunitID: Integer)
    begin
        if not Get(UserId, "Object Type"::Codeunit, CodeunitID) then
            InitSetupCU(CodeunitID);
        TransferFields(BusChartUserSetup, false);
        Modify();
    end;
}

