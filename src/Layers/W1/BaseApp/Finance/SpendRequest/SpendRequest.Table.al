// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using System.Security.AccessControl;

table 6840 "Spend Request"
{
    Caption = 'Spend Request';
    ReplicateData = false;
    DataClassification = CustomerContent;
    DataCaptionFields = "No.", Purpose;
    Permissions = tabledata "Spend Request Detail" = rimd,
                  tabledata "Spend Request To G/L Link" = rimd;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the unique identifier of the spend request.';
            trigger OnValidate()
            var
                GLSetup: Record "General Ledger Setup";
                NoSeries: Codeunit "No. Series";
            begin
                TestStatusOpen();
                if "No." <> xRec."No." then begin
                    GLSetup.Get();
                    if GLSetup."Spend Request No. Series" <> '' then
                        NoSeries.TestManual(GLSetup."Spend Request No. Series");
                end;
            end;
        }
        field(2; Type; Enum "Spend Request Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type of the spend request.';
            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(3; "Requested By"; Code[20])
        {
            Caption = 'Requested By';
            TableRelation = Employee;
            ToolTip = 'Specifies the employee who requested the spend request.';
            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6; Status; Enum "Spend Request Status")
        {
            Caption = 'Status';
            Editable = false;
            ToolTip = 'Specifies the approval status of the spend request.';
        }
        field(7; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            ToolTip = 'The G/L Account that the expenses will primarily be posted to.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(8; Purpose; Text[1000])
        {
            Caption = 'Purpose';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the purpose of the spend request.';
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency used for estimation. The currency amount will automatically be converted into Total Expected Amount (LCY)';
            DataClassification = CustomerContent;
            TableRelation = Currency;
            trigger OnValidate()
            begin
                TestStatusOpen();
                ChangeCurrency(xRec."Currency Code");
            end;
        }
        field(10; "Total Expected Amount"; Decimal)
        {
            Caption = 'Total Expected Amount';
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            ToolTip = 'Specifies the total expected amount of the spend request in the currency specified.';
            trigger OnValidate()
            begin
                TestStatusOpen();
                Rec."Total Expected Amount (LCY)" := Round(Rec."Currency Exchange Rate" * Rec."Total Expected Amount");
                Rec.CalcFields("Total Line Amount (LCY)");
                if Rec."Total Expected Amount (LCY)" < Rec."Total Line Amount (LCY)" then
                    Error(CannotBeLessThanSumOfLinesErr);
            end;
        }
        field(11; "Currency Exchange Rate"; Decimal)
        {
            Caption = 'Currency Exchange Rate';
            Editable = false;
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            ToolTip = 'Specifies the most recent exchange rate for the specified currency (1 = pari).';
            trigger OnValidate()
            begin
                TestStatusOpen();
                "Total Expected Amount (LCY)" := Round("Currency Exchange Rate" * "Total Expected Amount");
            end;
        }
        field(12; "Total Expected Amount (LCY)"; Decimal)
        {
            Caption = 'Total Expected Amount (LCY)';
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Specifies the total expected amount of the spend request.';
            trigger OnValidate()
            var
                Currency: Record Currency;
            begin
                TestStatusOpen();
                if "Currency Code" = '' then
                    Currency.InitRoundingPrecision()
                else
                    Currency.Get("Currency Code");
                if "Currency Exchange Rate" = 0 then
                    "Currency Exchange Rate" := 1;
                "Total Expected Amount" := Round("Total Expected Amount (LCY)" / "Currency Exchange Rate", Currency."Amount Rounding Precision");
            end;
        }
        field(13; "Expected Start Date"; Date)
        {
            Caption = 'Expected Start Date';
            ToolTip = 'Specifies the expected start date of the spend request.';
            trigger OnValidate()
            begin
                TestStatusOpen();
                CheckStartAndEndDate();
            end;
        }
        field(14; "Expected End Date"; Date)
        {
            Caption = 'Expected End Date';
            ToolTip = 'Specifies the expected end date of the spend request.';
            trigger OnValidate()
            begin
                TestStatusOpen();
                CheckStartAndEndDate();
            end;
        }
        field(15; "Approved/Rejected by User ID"; Guid)
        {
            Caption = 'Approved/Rejected by User ID';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the user ID who approved or rejected the spend request.';
            TableRelation = User."User Security ID";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(16; "Approved/Rejected by User Name"; Code[50])
        {
            Caption = 'Approved/Rejected by User Name';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the user name who approved or rejected the spend request.';
            TableRelation = User."User Name";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(17; "Approved/Rejected At"; DateTime)
        {
            Caption = 'Approved/Rejected At';
            ToolTip = 'Specifies the time when the spend request was approved or rejected.';
            Editable = false;
            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(18; "Closed At"; DateTime)
        {
            Caption = 'Closed At';
            ToolTip = 'Specifies the time when the spend request was closed.';
            Editable = false;
        }
        field(19; "Closed By Document No."; Code[20])
        {
            Caption = 'Closed By Document No.';
            ToolTip = 'Specifies the document no. of the transaction that closed the spend request.';
            Editable = false;
        }
        field(20; "Total Spent Amount (LCY)"; Decimal)
        {
            Caption = 'Total Spent Amount';
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Specifies the total spent amount of the spend request.';
            FieldClass = FlowField;
            CalcFormula = sum("Spend Request To G/L Link".Amount where("Spend Request No." = field("No.")));
        }
        field(21; "Total Line Amount (LCY)"; Decimal)
        {
            Caption = 'Total Line Amount';
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Specifies the total amount in local currency for all the detail lines.';
            FieldClass = FlowField;
            CalcFormula = sum("Spend Request Detail"."Expected Amount (LCY)" where("Spend Request No." = field("No.")));
        }
    }
    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; Status)
        {
        }
        key(Key3; "Requested By")
        {
        }

    }
    fieldgroups
    {
        fieldgroup(DropDown; "No.", Type, "Requested By", Purpose, Status)
        {
        }
        fieldgroup(Brick; "No.", Purpose, "Requested By", Status, "Total Expected Amount")
        {
        }
    }

    trigger OnInsert()
    var
        GLSetup: Record "General Ledger Setup";
        SpendRequest: Record "Spend Request";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." <> '' then exit;
        GLSetup.Get();
        if GLSetup."Spend Request No. Series" <> '' then
            Rec."No." := NoSeries.GetNextNo(GLSetup."Spend Request No. Series")
        else begin
            SpendRequest.SetLoadFields("No.");
            if SpendRequest.FindLast() then;
            if SpendRequest."No." = '' then
                SpendRequest."No." := '00000000';
            Rec."No." := IncStr(SpendRequest."No.");
        end;
    end;

    trigger OnModify()
    begin
        Rec.TestField(Status, Rec.Status::Open);
    end;

    trigger OnDelete()
    var
        SpendRequestDetail: Record "Spend Request Detail";
        SpendReqToGLLink: Record "Spend Request To G/L Link";
    begin
        Rec.CalcFields("Total Spent Amount (LCY)");
        if Rec."Total Spent Amount (LCY)" <> 0 then
            Error(CannotDeleteErr);
        SpendRequestDetail.SetRange("Spend Request No.", Rec."No.");
        SpendRequestDetail.DeleteAll();
        SpendReqToGLLink.SetRange("Spend Request No.", Rec."No.");
        SpendReqToGLLink.DeleteAll();
    end;

    var
        EndBeforeStartErr: Label 'Expected End Date cannot be before Expected Start Date.';
        CannotDeleteErr: Label 'You cannot delete a spend request that has expenses posted against it.';
        CannotBeLessThanSumOfLinesErr: Label 'You cannot specify an amount less than the total of the lines.';

    local procedure CheckStartAndEndDate()
    begin
        if ("Expected Start Date" <> 0D) and ("Expected End Date" <> 0D) then
            if "Expected End Date" < "Expected Start Date" then
                Error(EndBeforeStartErr);
    end;

    /// <summary>
    /// Allows the user to select a number from another no. series.
    /// </summary>
    internal procedure AssistEditNo() Result: Boolean
    var
        GLSetup: Record "General Ledger Setup";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
    begin
        GLSetup.Get();
        GLSetup.TestField("Spend Request No. Series");
        NoSeriesCode := GLSetup."Spend Request No. Series";
        if NoSeries.LookupRelatedNoSeries(NoSeriesCode, NoSeriesCode, NoSeriesCode) then begin
            "No." := NoSeries.GetNextNo(NoSeriesCode);
            exit(true);
        end;
    end;

    /// <summary>
    /// Ensures the spend request is still in the Open status, which is required before any field can be modified.
    /// </summary>
    procedure TestStatusOpen()
    begin
        Rec.TestField(Status, Status::Open);
    end;

    /// <summary>
    /// Applies an incremental change to the Total Expected Amount and refreshes the LCY total using the
    /// document currency factor. Called by detail tables (generic or layer-specific) when their amounts change.
    /// </summary>
    /// <param name="Delta">Change to apply to Total Expected Amount.</param>
    internal procedure AddToTotalExpectedAmount(DeltaLCY: Decimal)
    begin
        if DeltaLCY = 0 then
            exit;

        Rec.Validate("Total Expected Amount (LCY)", Rec."Total Expected Amount (LCY)" + DeltaLCY);
        Rec.Modify();
    end;

    internal procedure ChangeCurrency(xCurrencyCode: Code[10])
    var
        Currency: Record Currency;
        SpendRequestDetail: Record "Spend Request Detail";
    begin
        if Rec."Currency code" = xCurrencyCode then
            exit;
        if Rec."Currency code" = '' then begin
            Currency.InitRoundingPrecision();
            Rec."Currency Exchange Rate" := 1
        end else begin
            Currency.Get(Rec."Currency Code");
            Rec."Currency Exchange Rate" := Currency.GetExchangeRate(Today());
        end;
        if Rec."Currency Exchange Rate" = 0 then
            Rec."Currency Exchange Rate" := 1;

        "Total Expected Amount" := Round(Rec."Total Expected Amount (LCY)" / Rec."Currency Exchange Rate", Currency."Amount Rounding Precision");

        SpendRequestDetail.SetRange("Spend Request No.", Rec."No.");
        SpendRequestDetail.SetRange("Currency Code", xCurrencyCode);
        if not SpendRequestDetail.FindSet(true) then
            exit;
        repeat
            SpendRequestDetail."Currency Code" := Rec."Currency Code";
            SpendRequestDetail."Currency Exchange Rate" := Rec."Currency Exchange Rate";
            SpendRequestDetail."Expected Amount" := Round(SpendRequestDetail."Expected Amount (LCY)" / SpendRequestDetail."Currency Exchange Rate", Currency."Amount Rounding Precision");
            SpendRequestDetail.Modify();
        until SpendRequestDetail.Next() = 0;
        Rec.Modify();
    end;

    internal procedure UpdateCurrencyExchangeRate()
    var
        Currency: Record Currency;
        SpendRequestDetail: Record "Spend Request Detail";
    begin
        if Rec."Currency code" = '' then
            Rec."Currency Exchange Rate" := 1
        else begin
            Currency.Get(Rec."Currency Code");
            Rec."Currency Exchange Rate" := Currency.GetExchangeRate(Today());
        end;

        "Total Expected Amount (LCY)" := Round("Currency Exchange Rate" * "Total Expected Amount");

        SpendRequestDetail.SetRange("Spend Request No.", Rec."No.");
        if not SpendRequestDetail.FindSet(true) then
            exit;
        "Total Expected Amount (LCY)" := 0;
        repeat
            SpendRequestDetail.UpdateCurrencyExchangeRate();
            SpendRequestDetail.Modify();
            Rec."Total Expected Amount (LCY)" += SpendRequestDetail."Expected Amount (LCY)";
        until SpendRequestDetail.Next() = 0;
        Rec.Modify();
    end;
}
