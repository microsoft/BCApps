// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;

table 7000022 "Closed Payment Order"
{
    Caption = 'Closed Payment Order';
    DrillDownPageID = "Closed Payment Orders List";
    LookupPageID = "Closed Payment Orders List";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(4; "Bank Account Name"; Text[100])
        {
            CalcFormula = lookup("Bank Account".Name where("No." = field("Bank Account No.")));
            Caption = 'Bank Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(8; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(9; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = exist("BG/PO Comment Line" where("BG/PO No." = field("No."),
                                                            Type = filter(Payable)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(15; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(16; "Amount Grouped"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Closed Cartera Doc."."Amount for Collection" where("Bill Gr./Pmt. Order No." = field("No."),
                                                                                   "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   Status = field("Status Filter"),
                                                                                   Type = const(Payable)));
            Caption = 'Amount Grouped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Status Filter"; Enum "Cartera Document Status")
        {
            Caption = 'Status Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(20; "Closing Date"; Date)
        {
            Caption = 'Closing Date';
        }
        field(29; "Payment Order Expenses Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Payment Order Expenses Amt.';
        }
        field(33; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(35; "Amount Grouped (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Closed Cartera Doc."."Amt. for Collection (LCY)" where("Bill Gr./Pmt. Order No." = field("No."),
                                                                                       "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                       Status = field("Status Filter"),
                                                                                       Type = const(Payable)));
            Caption = 'Amount Grouped (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Posting Date")
        {
            SumIndexFields = "Payment Order Expenses Amt.";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ClosedDoc.SetRange("Bill Gr./Pmt. Order No.", "No.");
        ClosedDoc.DeleteAll();

        BGPOCommentLine.SetRange("BG/PO No.", "No.");
        BGPOCommentLine.DeleteAll();
    end;

    var
        Text1100000: Label 'untitled';
        ClosedPmtOrd: Record "Closed Payment Order";
        ClosedDoc: Record "Closed Cartera Doc.";
        BGPOCommentLine: Record "BG/PO Comment Line";

    [Scope('OnPrem')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        CarteraReportSelection: Record "Cartera Report Selections";
    begin
        ClosedPmtOrd.Copy(Rec);
        CarteraReportSelection.SetRange(Usage, CarteraReportSelection.Usage::"Closed Payment Order");
        CarteraReportSelection.SetFilter("Report ID", '<>0');
        CarteraReportSelection.Find('-');
        repeat
            REPORT.RunModal(CarteraReportSelection."Report ID", ShowRequestForm, false, ClosedPmtOrd);
        until CarteraReportSelection.Next() = 0;
    end;

    procedure Caption(): Text
    begin
        if "No." = '' then
            exit(Text1100000);
        CalcFields("Bank Account Name");
        exit(StrSubstNo('%1 %2', "No.", "Bank Account Name"));
    end;
}

