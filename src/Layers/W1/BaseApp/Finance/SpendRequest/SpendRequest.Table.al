// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using System.Environment.Configuration;
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
                CreateDimFromDefaultDim(FieldNo("Requested By"));
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
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestStatusOpen();
                CreateDimFromDefaultDim(FieldNo("G/L Account No."));
            end;
        }
        field(8; Purpose; Text[1000])
        {
            Caption = 'Purpose';
            ToolTip = 'Specifies the purpose of the spend request.';
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency used for estimation. The currency amount will automatically be converted into Total Expected Amount (LCY)';
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
            AutoFormatType = 0;
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
            Caption = 'Total Spent Amount (LCY)';
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
        /// <summary>
        /// Specifies the code for the first global dimension used for analysis and reporting.
        /// </summary>
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup page.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        /// <summary>
        /// Specifies the code for the second global dimension used for analysis and reporting.
        /// </summary>
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup page.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        /// <summary>
        /// Specifies the identifier for the combination of dimensions applied to the document.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDocDim();
            end;

            trigger OnValidate()
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
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
        User: Record User;
        Employee: Record Employee;
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
        if Rec."Requested By" = '' then
            if User.ReadPermission() and Employee.ReadPermission() then
                if User.Get(UserSecurityId()) then
                    if User."Authentication Email" <> '' then begin
                        Employee.SetRange("Company E-Mail", User."Authentication Email");
                        if Employee.FindFirst() then
                            Rec."Requested By" := Employee."No.";
                    end;
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
        ChangeCurrCodeOnLineQst: Label 'You have changed the currency code on the expense request. Do you also want to update the lines that had the same currency code?';
        SpendRequestIsUsedMsg: Label 'Spend request %1 was approved for %2 and current allocation is %3.', Comment = '%1 is a document no., %2 and %3 are amounts in local currency.';
        SpendRequestCloseQst: Label 'Do you want to close spend request %1 after posting this entry?', Comment = '%1 is a document no.';
        SkipSpendRequestClose: Boolean;

    /// <summary>
    /// Returns the difference between estimated amount and actually spent amount
    /// </summary>
    /// <returns></returns>
    procedure GetRemainingAmountLCY(): Decimal
    begin
        exit(Rec."Total Expected Amount (LCY)" - Rec."Total Spent Amount (LCY)");
    end;

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
    /// Opens a page for editing dimensions for the sales header.
    /// If dimensions are changed, they're updated on the sales lines as well.
    /// </summary>
    procedure ShowDocDim()
    var
        DimMgt: Codeunit DimensionManagement;
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" := DimMgt.EditDimensionSet(Rec, "Dimension Set ID", StrSubstNo('%1 %2', Rec.TableCaption, "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then
            Modify();
    end;

    /// <summary>
    /// Verifies whether the provided shortcut dimension code and value are valid.
    /// If valid, assigns it to the sales document.
    /// </summary>
    /// <remarks>
    /// If sales lines exist, the dimensions are updated on the lines as well.
    /// </remarks>
    /// <param name="FieldNumber">Number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">Value of the shortcut dimension.</param>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if OldDimSetID <> "Dimension Set ID" then
            if not IsNullGuid(Rec.SystemId) then
                Modify();
    end;

    /// <summary>
    /// Initializes the dimensions for the document from default dimensions for the related entry specified in the field.
    /// </summary>
    /// <param name="FieldNo">The field number for which to initialize the dimensions.</param>
    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Employee, Rec."Requested By", FieldNo = Rec.FieldNo("Requested By"));
        DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", Rec."G/L Account No.", FieldNo = Rec.FieldNo("G/L Account No."));
    end;

    /// <summary>
    /// Creates and assigns dimensions for the sales header based on the provided default dimension sources.
    /// </summary>
    /// <remarks>
    /// If sales lines exist and the dimension set has changed the dimensions are updated on the lines as well.
    /// </remarks>
    /// <param name="DefaultDimSource">The list of default dimension sources.</param>
    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := DimMgt.GetRecDefaultDimID(Rec, CurrFieldNo, DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
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
        if Rec."Currency Code" = xCurrencyCode then
            exit;
        if Rec."Currency Code" = '' then begin
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
        if not Confirm(ChangeCurrCodeOnLineQst) then
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
        if Rec."Currency Code" = '' then
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

    /// <summary>
    /// Validates that the spendrequest is approved, asks if should be closed and checks if there's room for the new amount
    /// </summary>
    /// <param name="SpendRequestNo"></param>
    /// <param name="SpendRequestclose"></param>
    /// <param name="NewAmountLCY"></param>
    procedure ValidateSpendRequest(SpendRequestNo: Code[20]; var SpendRequestclose: Boolean; SourceCode: Code[10]; NewAmountLCY: Decimal)
    begin
        ValidateSpendRequest(SpendRequestNo, SpendRequestclose, SourceCode);
        if NewAmountLCY <> 0 then
            CheckSpendRequestAmount(SpendRequestNo, SourceCode, NewAmountLCY);
    end;

    /// <summary>
    /// Validates that the spendrequest is approved and asks if should be closed
    /// </summary>
    /// <param name="SpendRequestNo"></param>
    /// <param name="SpendRequestclose"></param>
    procedure ValidateSpendRequest(SpendRequestNo: Code[20]; var SpendRequestclose: Boolean; SourceCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        if SpendRequestNo = '' then begin
            SpendRequestclose := false;
            exit;
        end;
        Rec.SetAutoCalcFields("Total Spent Amount (LCY)");
        Rec.Get(SpendRequestNo);
        IsHandled := false;
        OnValidateSpendRequestOnBeforeTestStatusApproved(Rec, SourceCode, IsHandled);
        if not IsHandled then
            Rec.TestField(Status, Rec.Status::Approved);

        if GuiAllowed() and not SkipSpendRequestClose then
            SpendRequestclose := Confirm(SpendRequestCloseQst, true, Rec."No.");
    end;

    /// <summary>
    /// Sets whether the confirmation to close the spend request should be skipped during validation.
    /// When set to true, ValidateSpendRequest does not prompt to close the spend request.
    /// </summary>
    /// <param name="NewSkipSpendRequestClose">True to skip the close confirmation; otherwise false.</param>
    procedure SetSkipSpendRequestClose(NewSkipSpendRequestClose: Boolean)
    begin
        SkipSpendRequestClose := NewSkipSpendRequestClose;
    end;

    /// <summary>
    /// Checks if there's room for the new amount (absolute value)
    /// </summary>
    /// <param name="SpendRequestNo"></param>
    /// <param name="NewAmountLCY"></param>
    procedure CheckSpendRequestAmount(SpendRequestNo: Code[20]; SourceCode: Code[10]; NewAmountLCY: Decimal)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        AlreadyAllocatedNotification: Notification;
        IsHandled: Boolean;
    begin
        if NewAmountLCY = 0 then
            exit;
        NewAmountLCY := Abs(NewAmountLCY);
        Rec.SetAutoCalcFields("Total Spent Amount (LCY)");
        Rec.Get(SpendRequestNo);
        IsHandled := false;
        OnCheckSpendRequestAmountOnBeforeTestStatusApproved(Rec, SourceCode, IsHandled);
        if not IsHandled then
            Rec.TestField(Status, Rec.Status::Approved);
        if GuiAllowed() then
            if Rec."Total Spent Amount (LCY)" + NewAmountLCY > Rec."Total Expected Amount (LCY)" then begin
                AlreadyAllocatedNotification.Scope := AlreadyAllocatedNotification.Scope::LocalScope;
                AlreadyAllocatedNotification.Message := StrSubstNo(SpendRequestIsUsedMsg, Rec."No.", Rec."Total Expected Amount (LCY)", Rec."Total Spent Amount (LCY)");
                NotificationLifecycleMgt.SendNotification(AlreadyAllocatedNotification, Rec.RecordId);
            end;
    end;

    /// <summary>
    /// Integration event raised before verifying that the spend request has the Approved status during validation.
    /// </summary>
    /// <param name="SpendRequest">The spend request being validated.</param>
    /// <param name="IsHandled">Set to true to skip the standard approved-status check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateSpendRequestOnBeforeTestStatusApproved(var SpendRequest: Record "Spend Request"; SourceCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before verifying that the spend request has the Approved status while checking the amount.
    /// </summary>
    /// <param name="SpendRequest">The spend request being checked.</param>
    /// <param name="IsHandled">Set to true to skip the standard approved-status check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckSpendRequestAmountOnBeforeTestStatusApproved(var SpendRequest: Record "Spend Request"; SourceCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}
