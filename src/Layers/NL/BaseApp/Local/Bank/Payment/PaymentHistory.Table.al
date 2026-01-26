// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;

table 11000001 "Payment History"
{
    Caption = 'Payment History';
    DrillDownPageID = "Payment History List";
    LookupPageID = "Payment History List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run No."; Code[20])
        {
            Caption = 'Run No.';
            Editable = false;
        }
        field(2; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'New,Transmitted';
            OptionMembers = New,Transmitted;
        }
        field(3; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(5; "Sent On"; Date)
        {
            Caption = 'Sent On';
            Editable = false;
        }
        field(6; "Sent By"; Code[50])
        {
            Caption = 'Sent By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(7; "Our Bank"; Code[20])
        {
            Caption = 'Our Bank';
            Editable = false;
            TableRelation = "Bank Account"."No.";
        }
        field(8; "Export Protocol"; Code[20])
        {
            Caption = 'Export Protocol';
            Editable = false;
            TableRelation = "Export Protocol".Code;
        }
        field(9; "No. of Transactions"; Integer)
        {
            Caption = 'No. of Transactions';
            Editable = false;
        }
        field(10; "Day Serial Nr."; Integer)
        {
            Caption = 'Day Serial Nr.';
            Editable = false;
        }
        field(11; "File on Disk"; Text[250])
        {
            Caption = 'File on Disk';
            Editable = false;
        }
        field(12; "Number of Copies"; Integer)
        {
            Caption = 'Number of Copies';
            Editable = false;
        }
        field(13; "Remaining Amount"; Decimal)
        {
            CalcFormula = sum("Payment History Line".Amount where("Run No." = field("Run No."),
                                                                   Order = field("Order Filter"),
                                                                   Date = field("Date Filter"),
                                                                   "Our Bank" = field("Our Bank"),
                                                                   Status = filter(New | Transmitted | "Request for Cancellation")));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Order Filter"; Option)
        {
            Caption = 'Order Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Receipt,Collection,Payment';
            OptionMembers = Receipt,Collection,Payment;
        }
        field(15; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(16; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series".Code;
        }
        field(17; Export; Boolean)
        {
            Caption = 'Export';
            InitValue = true;
        }
        field(18; "Print Docket"; Boolean)
        {
            Caption = 'Print Docket';
            InitValue = false;
        }
        field(19; Checksum; Text[256])
        {
            Caption = 'Checksum';
            Editable = false;
        }
        field(50; "Account No."; Text[30])
        {
            Caption = 'Account No.';
            Editable = false;
        }
        field(100; "Account Holder Name"; Text[100])
        {
            Caption = 'Account Holder Name';
            Editable = false;
        }
        field(101; "Account Holder Address"; Text[100])
        {
            Caption = 'Account Holder Address';
            Editable = false;
        }
        field(102; "Account Holder Post Code"; Code[20])
        {
            Caption = 'Account Holder Post Code';
            Editable = false;
            TableRelation = "Post Code";
        }
        field(103; "Account Holder City"; Text[50])
        {
            Caption = 'Account Holder City';
            Editable = false;
        }
        field(104; "Acc. Hold. Country/Region Code"; Code[10])
        {
            Caption = 'Acc. Hold. Country/Region Code';
            Editable = false;
            TableRelation = "Country/Region".Code;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(11400; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(11401; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
    }

    keys
    {
        key(Key1; "Our Bank", "Run No.")
        {
            Clustered = true;
        }
        key(Key2; "Our Bank", "Export Protocol", Status, "User ID")
        {
        }
        key(Key3; "Export Protocol", "Sent On", "Day Serial Nr.")
        {
        }
        key(Key4; "Our Bank", Status)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PaymentHistLine.SetRange("Our Bank", "Our Bank");
        PaymentHistLine.SetRange("Run No.", "Run No.");
        PaymentHistLine.DeleteAll(true);
    end;

    trigger OnRename()
    begin
        Error(Text1000000, TableCaption);
    end;

    var
        Text1000000: Label '%1 cannot be renamed';
        PaymentHistLine: Record "Payment History Line";

    procedure ExportToPaymentFile()
    var
        GenJnlLine: Record "Gen. Journal Line";
        PaymentHistory: Record "Payment History";
        ExportProtocol: Record "Export Protocol";
        SEPACreatePaymentFile: Codeunit "SEPA CT-Export File";
    begin
        ExportProtocol.Get("Export Protocol");
        ExportProtocol.TestField("Export ID");
        case ExportProtocol."Export Object Type" of
            ExportProtocol."Export Object Type"::Report:
                begin
                    PaymentHistory.SetRange("Our Bank", "Our Bank");
                    PaymentHistory.SetRange("Run No.", "Run No.");
                    PaymentHistory.SetRange("Export Protocol", "Export Protocol");
                    REPORT.RunModal(ExportProtocol."Export ID", true, true, PaymentHistory);
                end;
            ExportProtocol."Export Object Type"::XMLPort:
                begin
                    GenerateExportfilename(false);
                    // Pass Primary Key fields as filters on GenJnlLine
                    GenJnlLine.SetRange("Journal Template Name", '');
                    GenJnlLine.SetRange("Journal Batch Name", '');
                    GenJnlLine.SetRange("Bal. Account No.", "Our Bank");
                    GenJnlLine.SetRange("Document No.", "Run No.");
                    if SEPACreatePaymentFile.Export(GenJnlLine, ExportProtocol."Export ID", "File on Disk") then begin
                        Get("Our Bank", "Run No.");
                        Export := false;
                        if Status = Status::New then
                            Validate(Status, Status::Transmitted);
                        Modify();
                    end;
                end;
        end;
    end;

    procedure GenerateExportfilename(New: Boolean) FileName: Text[250]
    begin
        OnBeforeGenerateExportfilename(Rec, New);
        if ("File on Disk" = '') or New then begin
            "Day Serial Nr." := GetNextDaySerialNo();
            "Sent On" := Today;
            "File on Disk" := GenerateNewFileName();
            "Sent By" := UserId();
        end else
            "Number of Copies" := "Number of Copies" + 1;

        Modify();
        exit("File on Disk");
    end;

    local procedure GenerateNewFileName() FileName: Text[250]
    var
        ExportProtocol: Record "Export Protocol";
    begin
        FileName := StrSubstNo('%1', Date2DMY("Sent On", 1) * 10000 + Date2DMY("Sent On", 2) * 100 + ("Day Serial Nr." mod 100));

        ExportProtocol.Get("Export Protocol");
        ExportProtocol.TestField("Default File Names");
        FileName := StrSubstNo(ExportProtocol."Default File Names", FileName);
    end;

    local procedure GetNextDaySerialNo(): Integer
    var
        PaymentHistory: Record "Payment History";
        LastDaySerialNo: Integer;
    begin
        LockTable();
        PaymentHistory.SetCurrentKey("Export Protocol", "Sent On", "Day Serial Nr.");
        PaymentHistory.SetRange("Export Protocol", "Export Protocol");
        PaymentHistory.SetRange("Sent On", Today);
        if PaymentHistory.FindLast() then
            LastDaySerialNo := PaymentHistory."Day Serial Nr.";
        exit(LastDaySerialNo + 1);
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Run No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateExportfilename(PaymentHistory: Record "Payment History"; New: Boolean)
    begin
    end;
}

