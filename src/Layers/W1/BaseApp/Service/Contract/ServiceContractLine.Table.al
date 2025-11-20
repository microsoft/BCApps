// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Setup;
using System.Utilities;

table 5964 "Service Contract Line"
{
    Caption = 'Service Contract Line';
    DrillDownPageID = "Serv. Contr. List (Serv. Item)";
    LookupPageID = "Serv. Contr. List (Serv. Item)";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contract Type"; Enum "Service Contract Type")
        {
            Caption = 'Contract Type';
        }
        field(2; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = field("Contract Type"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Contract Status"; Enum "Service Contract Status")
        {
            Caption = 'Contract Status';
        }
        field(5; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = "Service Item" where(Blocked = filter(" "));

            trigger OnValidate()
            var
                ServiceItemLine: Record "Service Item Line";
                ServContractMgt: Codeunit ServContractManagement;
                ConfirmManagement: Codeunit "Confirm Management";
                InvoicePeriod: DateFormula;
                LastInvoiceDate: Date;
                NewLastInvoiceDate: Date;
                ServiceItemNoIsNotEmpty: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateServiceItemNoOnBeforeOnValidate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                GetServContractHeader();
                if ServContractHeader."Last Invoice Date" <> 0D then begin
                    LastInvoiceDate := ServContractHeader."Last Invoice Date";
                    Evaluate(InvoicePeriod, ServContractMgt.GetInvoicePeriodText(ServContractHeader."Invoice Period"));
                    NewLastInvoiceDate := CalcDate(InvoicePeriod, LastInvoiceDate);
                    if (ServContractHeader."Expiration Date" <> 0D) and
                       (NewLastInvoiceDate > ServContractHeader."Expiration Date")
                    then
                        Error(Text025, ServiceItemLine.TableCaption(), ServContractHeader.FieldCaption("Expiration Date"));
                end;

                IsHandled := false;
                OnValidateServiceItemNoOnBeforeCheckServContractHeaderStatus(Rec, xRec, IsHandled);
                if not IsHandled then
                    if (ServContractHeader.Status = ServContractHeader.Status::Signed) and (not "New Line") then
                        Error(Text013, FieldCaption("Service Item No."));

                ServiceItemNoIsNotEmpty := "Service Item No." <> '';
                OnValidateServiceItemNoOnAfterCalcServiceItemNoIsNotEmpty(Rec, ServiceItemNoIsNotEmpty, xRec, HideDialog);
                if ServiceItemNoIsNotEmpty then begin
                    GetServItem();
                    TestField("Customer No.");

                    IsHandled := false;
                    OnValidateServiceItemNoOnBeforeCheckSameCustomer(ServItem, ServContractHeader, IsHandled);
                    if not IsHandled then
                        if ServItem."Customer No." <> ServContractHeader."Customer No." then
                            Error(Text000, "Customer No.");

                    IsHandled := false;
                    OnValidateServiceItemNoOnBeforeCheckSameItemExist(Rec, IsHandled);
                    if not IsHandled then begin
                        ServContractLine.Reset();
                        ServContractLine.SetRange("Contract No.", "Contract No.");
                        ServContractLine.SetRange("Contract Type", "Contract Type");
                        ServContractLine.SetRange("Service Item No.", "Service Item No.");
                        ServContractLine.SetFilter("Line No.", '<>%1', "Line No.");
                        if not ServContractLine.IsEmpty() then
                            Error(Text003);
                    end;

                    if not HideDialog then begin
                        ServContractLine.Reset();
                        ServContractLine.SetCurrentKey("Service Item No.", "Contract Status");
                        ServContractLine.SetRange("Service Item No.", "Service Item No.");
                        ServContractLine.SetFilter("Contract Status", '<>%1', ServContractLine."Contract Status"::Cancelled);
                        ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                        ServContractLine.SetFilter("Contract No.", '<>%1', "Contract No.");
                        OnValidateServiceItemNoOnAfterServContractLineSetFiltersWithContractStatus(Rec, ServContractLine);
                        if not ServContractLine.IsEmpty() then begin
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text019, "Service Item No."), true)
                            then begin
                                "Service Item No." := xRec."Service Item No.";
                                exit;
                            end;
                        end else begin
                            ServContractLine.Reset();
                            ServContractLine.SetCurrentKey("Service Item No.");
                            ServContractLine.SetRange("Service Item No.", "Service Item No.");
                            ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Quote);
                            ServContractLine.SetFilter("Contract No.", '<>%1', "Contract No.");
                            if not ServContractLine.IsEmpty() then
                                if not ConfirmManagement.GetResponseOrDefault(
                                     StrSubstNo(Text019, "Service Item No."), true)
                                then begin
                                    "Service Item No." := xRec."Service Item No.";
                                    exit;
                                end;
                        end;
                    end;

                    if (ServItem."Ship-to Code" <> ServContractHeader."Ship-to Code") and
                       not HideDialog
                    then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text001, "Service Item No."), true)
                        then begin
                            "Service Item No." := xRec."Service Item No.";
                            exit;
                        end;
                    "Ship-to Code" := ServItem."Ship-to Code";
                end;
                ServContractLine := Rec;
                Init();
                OnValidateServiceItemNoOnAfterInit(Rec, ServContractLine);
                "Starting Date" := ServContractLine."Starting Date";
                "Contract Expiration Date" := ServContractLine."Contract Expiration Date";
                "Credit Memo Date" := ServContractLine."Credit Memo Date";
                "Next Planned Service Date" := ServContractLine."Next Planned Service Date";
                "Service Period" := ServContractLine."Service Period";
                "Customer No." := ServContractLine."Customer No.";
                if ServContractLine."Service Item No." <> '' then
                    "Ship-to Code" := ServContractLine."Ship-to Code"
                else
                    "Ship-to Code" := ServContractHeader."Ship-to Code";
                "Contract Status" := ServContractLine."Contract Status";
                "Service Item No." := ServContractLine."Service Item No.";
                if "Service Item No." = '' then
                    exit;
                Description := ServItem.Description;
                "Serial No." := ServItem."Serial No.";
                "Service Item Group Code" := ServItem."Service Item Group Code";
                "Item No." := ServItem."Item No.";
                "Variant Code" := ServItem."Variant Code";
                "Unit of Measure Code" := ServItem."Unit of Measure Code";
                ServContractMgt.CheckItemServiceBlocked(Rec);
                if (ServContractHeader."Response Time (Hours)" < ServItem."Response Time (Hours)") and
                   (ServContractHeader."Response Time (Hours)" <> 0)
                then
                    "Response Time (Hours)" := ServContractHeader."Response Time (Hours)"
                else
                    if ServItem."Response Time (Hours)" <> 0 then
                        "Response Time (Hours)" := ServItem."Response Time (Hours)"
                    else
                        "Response Time (Hours)" := ServContractHeader."Response Time (Hours)";
                ServMgtSetup.Get();
                Validate("Line Cost", ServItem."Default Contract Cost");
                Validate("Line Value", ServItem."Default Contract Value");
                Validate("Line Discount %", ServItem."Default Contract Discount %");

                OnValidateServiceItemNoOnBeforeModify(ServItem, ServContractHeader);

                if ServContractLine.Get("Contract Type", "Contract No.", "Line No.") then begin
                    UseServContractLineAsxRec := true;
                    Modify(true);
                end;
            end;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(7; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            begin
                TestStatusOpen();
                TestField("Item No.");
            end;
        }
        field(8; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            TableRelation = "Service Item Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
                TestField("Service Item No.");
            end;
        }
        field(9; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(10; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            Editable = false;
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item where(Type = const(Inventory), Blocked = const(false), "Service Blocked" = const(false));

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Item No." <> xRec."Item No." then
                    TestField("Service Item No.", '');

                if "Item No." <> '' then begin
                    Item.Get("Item No.");
                    Currency.InitRoundingPrecision();
                    Description := Item.Description;
                    "Unit of Measure Code" := Item."Sales Unit of Measure";
                    GetServContractHeader();
                    "Response Time (Hours)" := ServContractHeader."Response Time (Hours)";
                    ServMgtSetup.Get();
                    "Line Cost" :=
                      Round(Item."Unit Cost" * ServMgtSetup."Contract Value %" / 100,
                        Currency."Amount Rounding Precision");
                    "Line Discount %" := 0;
                    case ServMgtSetup."Contract Value Calc. Method" of
                        ServMgtSetup."Contract Value Calc. Method"::"Based on Unit Price":
                            "Line Value" :=
                              Round(Item."Unit Price" * ServMgtSetup."Contract Value %" / 100,
                                Currency."Amount Rounding Precision");
                        ServMgtSetup."Contract Value Calc. Method"::"Based on Unit Cost":
                            "Line Value" :=
                              Round(Item."Unit Cost" * ServMgtSetup."Contract Value %" / 100,
                                Currency."Amount Rounding Precision");
                    end;
                    Validate("Line Value", "Line Value");
                end else begin
                    "Unit of Measure Code" := '';
                    "Variant Code" := '';
                    "Serial No." := '';
                end;
            end;
        }
        field(12; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if ("Item No." = filter(<> '')) "Item Unit of Measure".Code where("Item No." = field("Item No."))
            else
            "Unit of Measure";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Unit of Measure Code" <> xRec."Unit of Measure Code" then begin
                    TestField("Service Item No.", '');
                    TestField("Item No.");
                end;
            end;
        }
        field(13; "Response Time (Hours)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(14; "Last Planned Service Date"; Date)
        {
            Caption = 'Last Planned Service Date';
            Editable = false;
        }
        field(15; "Next Planned Service Date"; Date)
        {
            Caption = 'Next Planned Service Date';

            trigger OnValidate()
            begin
                TestStatusOpen();
                if ("Next Planned Service Date" <> 0D) and
                   ("Next Planned Service Date" < "Starting Date")
                then
                    Error(Text009, FieldCaption("Next Planned Service Date"), FieldCaption("Starting Date"));
            end;
        }
        field(16; "Last Service Date"; Date)
        {
            Caption = 'Last Service Date';
        }
        field(17; "Last Preventive Maint. Date"; Date)
        {
            Caption = 'Last Preventive Maint. Date';
            Editable = false;
        }
        field(18; "Invoiced to Date"; Date)
        {
            Caption = 'Invoiced to Date';
            Editable = false;
        }
        field(19; "Credit Memo Date"; Date)
        {
            Caption = 'Credit Memo Date';

            trigger OnValidate()
            begin
                TestStatusOpen();

                TestField(Credited, false);

                CheckCreditMemoDate();
            end;
        }
        field(20; "Contract Expiration Date"; Date)
        {
            Caption = 'Contract Expiration Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnBeforeValidateContractExpirationDate(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField(Credited, false);

                ServContractHeader.Get("Contract Type", "Contract No.");

                if (not ServContractHeader.Prepaid) and
                   (xRec."Contract Expiration Date" <= "Invoiced to Date") and
                   (xRec."Contract Expiration Date" <> 0D)
                then
                    if ("Contract Expiration Date" > "Invoiced to Date") or
                       ("Contract Expiration Date" = 0D)
                    then
                        Error(
                          Text024,
                          FieldCaption("Contract Expiration Date"));

                if "Contract Expiration Date" = 0D then begin
                    "Credit Memo Date" := 0D;
                    exit;
                end;

                if "Contract Expiration Date" < "Starting Date" then
                    Error(
                      Text009,
                      FieldCaption("Contract Expiration Date"),
                      FieldCaption("Starting Date"));

                if ServContractHeader."Expiration Date" <> 0D then
                    if "Contract Expiration Date" > ServContractHeader."Expiration Date" then
                        Error(
                          Text017,
                          FieldCaption("Contract Expiration Date"),
                          ServContractHeader.FieldCaption("Expiration Date"));

                if "Contract Expiration Date" < "Credit Memo Date" then
                    Error(
                      Text009,
                      FieldCaption("Contract Expiration Date"),
                      FieldCaption("Credit Memo Date"));

                if "Credit Memo Date" = 0D then
                    "Credit Memo Date" := "Contract Expiration Date";

                if not ServContractHeader."Automatic Credit Memos" then begin
                    ServLedgEntry.Reset();
                    ServLedgEntry.SetCurrentKey(Type, "No.", "Entry Type", "Moved from Prepaid Acc.", "Posting Date", Open);
                    ServLedgEntry.SetRange(Type, ServLedgEntry.Type::"Service Contract");
                    ServLedgEntry.SetRange("No.", "Contract No.");
                    ServLedgEntry.SetRange("Moved from Prepaid Acc.", false);
                    ServLedgEntry.SetRange(Open, false);
                    ServLedgEntry.CalcSums("Amount (LCY)");
                    if ServLedgEntry."Amount (LCY)" <> 0 then
                        Message(Text011, "Contract No.");
                end;
            end;
        }
        field(21; "Service Period"; DateFormula)
        {
            Caption = 'Service Period';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(22; "Line Value"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Value';

            trigger OnValidate()
            begin
                if "Line Value" < 0 then
                    FieldError("Line Value");

                Validate("Line Discount %");
            end;
        }
        field(23; "Line Discount %"; Decimal)
        {
            BlankZero = true;
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnBeforeValidateLineDiscountPercent(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                Currency.InitRoundingPrecision();
                "Line Value" := Round("Line Value", Currency."Amount Rounding Precision");
                "Line Amount" :=
                  Round("Line Value" - "Line Value" * "Line Discount %" / 100,
                    Currency."Amount Rounding Precision");
                "Line Discount Amount" :=
                  Round("Line Value" - "Line Amount", Currency."Amount Rounding Precision");
                Profit := Round("Line Amount" - "Line Cost", Currency."Amount Rounding Precision");
            end;
        }
        field(24; "Line Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Amount';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();
                IsHandled := false;
                OnBeforeValidateLineAmount(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Line Value");
                Currency.InitRoundingPrecision();
                "Line Discount Amount" := Round("Line Value" - "Line Amount", Currency."Amount Rounding Precision");
                "Line Discount %" := "Line Discount Amount" / "Line Value" * 100;
                Profit := Round("Line Amount" - "Line Cost", Currency."Amount Rounding Precision");
            end;
        }
        field(28; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."), Blocked = const(false), "Service Blocked" = const(false));

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(29; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            Editable = false;
        }
        field(30; "New Line"; Boolean)
        {
            Caption = 'New Line';
            Editable = false;
            InitValue = true;
        }
        field(31; Credited; Boolean)
        {
            Caption = 'Credited';

            trigger OnValidate()
            begin
                TestStatusOpen();
                TestField("Contract Expiration Date");
            end;
        }
        field(32; "Line Cost"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Cost';

            trigger OnValidate()
            begin
                TestStatusOpen();
                Currency.InitRoundingPrecision();
                Profit := Round("Line Amount" - "Line Cost", Currency."Amount Rounding Precision");
            end;
        }
        field(33; "Line Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Line Discount Amount';

            trigger OnValidate()
            begin
                TestStatusOpen();
                Currency.InitRoundingPrecision();
                if "Line Value" <> 0 then
                    "Line Discount %" := "Line Discount Amount" / "Line Value" * 100
                else
                    "Line Discount %" := 0;
                "Line Amount" :=
                  Round("Line Value" - "Line Value" * "Line Discount %" / 100, Currency."Amount Rounding Precision");
                Profit := Round("Line Amount" - "Line Cost", Currency."Amount Rounding Precision");
            end;
        }
        field(34; Profit; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Profit';

            trigger OnValidate()
            begin
                TestStatusOpen();
                Currency.InitRoundingPrecision();
                "Line Amount" := Round(Profit + "Line Cost", Currency."Amount Rounding Precision");
                "Line Discount Amount" := Round("Line Value" - "Line Amount", Currency."Amount Rounding Precision");
                if "Line Value" <> 0 then
                    "Line Discount %" := "Line Discount Amount" / "Line Value" * 100;
            end;
        }
    }

    keys
    {
        key(Key1; "Contract Type", "Contract No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Contract No.", "Line No.", "Contract Type")
        {
        }
        key(Key3; "Service Item No.", "Contract Status")
        {
        }
        key(Key4; "Contract Type", "Contract No.", Credited, "New Line")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Line Amount", Profit;
        }
        key(Key5; "Customer No.", "Ship-to Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        TestStatusOpen();
        if "Contract Type" = "Contract Type"::Contract then begin
            GetServContractHeader();
            if ServContractHeader.Status = ServContractHeader.Status::Cancelled then
                Error(Text015, ServContractHeader.Status);
            if (ServContractHeader.Status = ServContractHeader.Status::Signed) and
               (not "New Line") and
               ServContractHeader."Automatic Credit Memos"
            then begin
                TestField("Contract Expiration Date");
                CODEUNIT.Run(CODEUNIT::CreateCreditfromContractLines, Rec);
            end;

            if (ServContractHeader.Status = ServContractHeader.Status::Signed) and
               (not "New Line") and
               (not ServContractHeader."Automatic Credit Memos")
            then
                if CreditMemoBaseExists() and
                   (not StatusCheckSuspended)
                then
                    if not ConfirmManagement.GetResponseOrDefault(Text022, true) then
                        Error(Text023);
            ServMgtSetup.Get();
            if "Service Item No." <> '' then begin
                if ServMgtSetup."Register Contract Changes" then
                    ContractChangeLog.LogContractChange(
                      "Contract No.", 1, FieldCaption("Service Item No."), 2,
                      Format("Service Item No."), '', "Service Item No.", "Line No.");
                ServLogMgt.ServItemRemovedFromContract(Rec);
            end else
                if ServMgtSetup."Register Contract Changes" then
                    ContractChangeLog.LogContractChange(
                      "Contract No.", 1, FieldCaption(Description), 2, Description, '', '', "Line No.");

            GetServContractHeader();
            if (not ServContractHeader."Allow Unbalanced Amounts") and
               (ServContractHeader.Status = ServContractHeader.Status::Signed)
            then
                ContractGainLossEntry.CreateEntry(
                    "Service Contract Change Type"::"Line Deleted", "Contract Type", "Contract No.", -"Line Amount", '');
        end;

        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Contract");
        ServCommentLine.SetRange("Table Subtype", "Contract Type");
        ServCommentLine.SetRange("No.", "Contract No.");
        ServCommentLine.SetRange(Type, ServCommentLine.Type::General);
        ServCommentLine.SetRange("Table Line No.", "Line No.");
        ServCommentLine.DeleteAll();

        UpdateContractAnnualAmount(true);
    end;

    trigger OnInsert()
    begin
        TestField(Description);
        GetServContractHeader();
        CheckServContractHeader();

        ServMgtSetup.Get();

        UpdateContractAnnualAmount(false);

        if ("Service Item No." = '') and ("Response Time (Hours)" = 0) then
            "Response Time (Hours)" := ServContractHeader."Response Time (Hours)";

        if "Contract Type" = "Contract Type"::Contract then
            if "Service Item No." <> '' then begin
                if ServMgtSetup."Register Contract Changes" then
                    ContractChangeLog.LogContractChange(
                      "Contract No.", 1, FieldCaption("Service Item No."), 1, '',
                      Format("Service Item No."), "Service Item No.", "Line No.");
                ServLogMgt.ServItemAddToContract(Rec);
            end else
                if ServMgtSetup."Register Contract Changes" then
                    ContractChangeLog.LogContractChange(
                      "Contract No.", 1, FieldCaption(Description), 1, '', Description, '', "Line No.");
    end;

    trigger OnModify()
    begin
        if UseServContractLineAsxRec then begin
            xRec := ServContractLine;
            UseServContractLineAsxRec := false;
        end;

        if ("Service Item No." = '') and
           ("Item No." = '') and
           (Description = '')
        then
            Error(Text016, FieldCaption(Description));

        ServMgtSetup.Get();
        if ServMgtSetup."Register Contract Changes" then
            if "Contract Type" = "Contract Type"::Contract then
                LogContractLineChanges(xRec);

        if Rec."Line Amount" <> xRec."Line Amount" then
            UpdateContractAnnualAmount(false);

        if "Service Item No." <> xRec."Service Item No." then begin
            ServLogMgt.ServItemAddToContract(Rec);
            ServLogMgt.ServItemRemovedFromContract(xRec);
        end;
    end;

    var
        Currency: Record Currency;
        Item: Record Item;
        ServMgtSetup: Record "Service Mgt. Setup";
        ServLedgEntry: Record "Service Ledger Entry";
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ServItem: Record "Service Item";
        ContractChangeLog: Record "Contract Change Log";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        ServCommentLine: Record "Service Comment Line";
        ServLogMgt: Codeunit ServLogManagement;
        HideDialog: Boolean;
        StatusCheckSuspended: Boolean;
        UseServContractLineAsxRec: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'This service item does not belong to customer no. %1.';
        Text001: Label 'Service item %1 has a different ship-to code for this customer.\\Do you want to continue?';
#pragma warning restore AA0470
        Text003: Label 'This service item already exists in this service contract.';
#pragma warning disable AA0470
        Text008: Label '%1 field value cannot be later than the %2 field value on the contract line.';
        Text009: Label 'The %1 cannot be less than the %2.';
        Text011: Label 'Service ledger entry exists for service contract line %1.\\You may need to create a credit memo.';
        Text013: Label 'You cannot change the %1 field on signed service contracts.';
        Text015: Label 'You cannot delete service contract lines on %1 service contracts.';
        Text016: Label 'Service contract lines must have at least a %1 filled in.';
        Text017: Label 'The %1 cannot be later than the %2.';
        Text018: Label 'You cannot reset %1 manually.';
        Text019: Label 'Service item %1 already belongs to one or more service contracts/quotes.\\Do you want to continue?';
        Text020: Label 'The service period for service item %1 under contract %2 has not yet started.';
        Text021: Label 'The service period for service item %1 under contract %2 has expired.';
#pragma warning restore AA0470
        Text022: Label 'If you delete this contract line while the Automatic Credit Memos check box is not selected, a credit memo will not be created.\Do you want to continue?';
        Text023: Label 'The update has been interrupted to respect the warning.';
#pragma warning disable AA0470
        Text024: Label 'You cannot enter a later date in or clear the %1 field on the contract line that has been invoiced for the period containing that date.';
        Text025: Label 'You cannot add a new %1 because the service contract has expired. Renew the %2 on the service contract.', Comment = 'You cannot add a new Service Item Line because the service contract has expired. Renew the Expiration Date on the service contract.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetupNewLine()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetupNewLine(Rec, IsHandled);
        if IsHandled then
            exit;

        if not ServContractHeader.Get("Contract Type", "Contract No.") then
            exit;
        "Customer No." := ServContractHeader."Customer No.";
        "Ship-to Code" := ServContractHeader."Ship-to Code";
        "Contract Status" := ServContractHeader.Status;
        "Contract Expiration Date" := ServContractHeader."Expiration Date";
        "Credit Memo Date" := "Contract Expiration Date";
        "Service Period" := ServContractHeader."Service Period";
        if ("Contract Type" = "Contract Type"::Contract) and
           ("Contract Status" = "Contract Status"::Signed)
        then
            "Starting Date" := WorkDate()
        else
            "Starting Date" := ServContractHeader."Starting Date";

        if "Starting Date" > ServContractHeader."First Service Date" then
            "Next Planned Service Date" := "Starting Date"
        else
            "Next Planned Service Date" := ServContractHeader."First Service Date";

        OnAfterSetupNewLine(Rec, ServContractHeader);
    end;

    local procedure GetServItem()
    var
        ServContractManagement: Codeunit ServContractManagement;
    begin
        TestField("Service Item No.");
        if "Service Item No." <> ServItem."No." then begin
            ServItem.Get("Service Item No.");
            ServContractManagement.CheckServiceItemBlockedForServiceContract(Rec);
        end;

        OnAfterGetServiceItem(Rec, ServItem);
    end;

    procedure CalculateNextServiceVisit()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateNextServiceVisit(Rec, IsHandled);
        if IsHandled then
            exit;

        ServMgtSetup.Get();
        if (Format("Service Period") <> '') and
           ("Next Planned Service Date" <> 0D)
        then begin
            GetServContractHeader();
            case ServMgtSetup."Next Service Calc. Method" of
                ServMgtSetup."Next Service Calc. Method"::Planned:
                    "Next Planned Service Date" := CalcDate("Service Period", "Last Planned Service Date");
                ServMgtSetup."Next Service Calc. Method"::Actual:
                    "Next Planned Service Date" := CalcDate("Service Period", "Last Service Date");
            end;
        end else
            "Next Planned Service Date" := 0D;

        OnAfterCalculateNextServiceVisit(ServContractHeader, ServMgtSetup);
    end;

    procedure UpdateContractAnnualAmount(Deleting: Boolean)
    var
        OldServContractHeader: Record "Service Contract Header";
        ServContractLine2: Record "Service Contract Line";
        LineAmount: Decimal;
        IsHandled: Boolean;
    begin
        GetServContractHeader();
        IsHandled := false;
        OnUpdateContractAnnualAmountOnAfterGetServContractHeader(Rec, ServContractHeader, IsHandled);
        if IsHandled then
            exit;

        if not ServContractHeader."Allow Unbalanced Amounts" then begin
            LineAmount := CalculateOtherLineAmounts();

            OldServContractHeader := ServContractHeader;
            if Deleting then
                ServContractHeader."Annual Amount" := LineAmount
            else begin
                ServContractHeader."Annual Amount" := LineAmount + "Line Amount";
                if not "New Line" then
                    ContractGainLossEntry.CreateEntry(
                        "Service Contract Change Type"::"Manual Update", "Contract Type", "Contract No.",
                        "Line Amount" - xRec."Line Amount", '')
                else
                    if ServContractHeader.Status = ServContractHeader.Status::Signed then
                        if ServContractLine2.Get("Contract Type", "Contract No.", "Line No.") then
                            ContractGainLossEntry.CreateEntry(
                                "Service Contract Change Type"::"Manual Update", "Contract Type", "Contract No.",
                                "Line Amount" - ServContractLine2."Line Amount", '')
                        else
                            ContractGainLossEntry.CreateEntry(
                                "Service Contract Change Type"::"Line Added", "Contract Type", "Contract No.",
                                "Line Amount", '');
            end;
            ServContractHeader.ValidateNextInvoicePeriod();
            ServContractHeader.SuspendStatusCheck(StatusCheckSuspended);
            ServContractHeader.Modify(true);
            if ServContractHeader."Contract Type" = ServContractHeader."Contract Type"::Contract then
                if ServMgtSetup."Register Contract Changes" then
                    ServContractHeader.UpdContractChangeLog(OldServContractHeader);
        end;
    end;

    local procedure CalculateOtherLineAmounts(): Decimal
    var
        ServContractLine2: Record "Service Contract Line";
    begin
        ServContractLine2.Reset();
        ServContractLine2.SetRange("Contract Type", "Contract Type");
        ServContractLine2.SetRange("Contract No.", "Contract No.");
        ServContractLine2.SetFilter("Line No.", '<>%1', "Line No.");
        OnCalculateOtherLineAmountsOnAfterSetFilters(ServContractLine2);
        ServContractLine2.CalcSums("Line Amount");
        exit(ServContractLine2."Line Amount");
    end;

    procedure HideDialogBox(Hide: Boolean)
    begin
        HideDialog := Hide;
    end;

    procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;
        GetServContractHeader();
        ServContractHeader.TestField("Change Status", ServContractHeader."Change Status"::Open);

        OnAfterTestStatusOpen(Rec, CurrFieldNo);
    end;

    local procedure CheckServContractHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServContractHeader(ServContractHeader, IsHandled);
        if IsHandled then
            exit;

        ServContractHeader.TestField("Customer No.");
        ServContractHeader.TestField("Contract No.");
        ServContractHeader.TestField("Starting Date");
        if "Service Item No." <> '' then begin
            ServContractHeader.TestField("Service Period");
            ServContractHeader.TestField("First Service Date");
        end;
    end;

    local procedure CheckCreditMemoDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCreditMemoDate(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if "Credit Memo Date" <> 0D then
            if "Credit Memo Date" > "Contract Expiration Date" then
                Error(
                  Text008,
                  FieldCaption("Credit Memo Date"), FieldCaption("Contract Expiration Date"));

        if "Credit Memo Date" <> xRec."Credit Memo Date" then
            if "Credit Memo Date" = 0D then
                Error(Text018, FieldCaption("Credit Memo Date"));
    end;

    procedure GetStatusCheckSuspended(): Boolean
    begin
        exit(StatusCheckSuspended);
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    local procedure GetServContractHeader()
    begin
        TestField("Contract No.");
        if ("Contract Type" <> ServContractHeader."Contract Type") or
           ("Contract No." <> ServContractHeader."Contract No.")
        then
            ServContractHeader.Get("Contract Type", "Contract No.");
    end;

    procedure ShowComments()
    begin
        ServContractHeader.Get("Contract Type", "Contract No.");
        ServContractHeader.TestField("Customer No.");
        TestField("Line No.");
        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Contract");
        ServCommentLine.SetRange("Table Subtype", "Contract Type");
        ServCommentLine.SetRange("No.", "Contract No.");
        ServCommentLine.SetRange(Type, ServCommentLine.Type::General);
        ServCommentLine.SetRange("Table Line No.", "Line No.");
        PAGE.RunModal(PAGE::"Service Comment Sheet", ServCommentLine);
    end;

    procedure ValidateServicePeriod(CurrentDate: Date)
    begin
        if "Starting Date" > CurrentDate then
            Error(Text020, "Service Item No.", "Contract No.");
        if "Contract Expiration Date" = 0D then begin
            ServContractHeader.Get(ServContractHeader."Contract Type"::Contract, "Contract No.");
            if (ServContractHeader."Expiration Date" <> 0D) and
               (ServContractHeader."Expiration Date" <= CurrentDate)
            then
                Error(Text021, "Service Item No.", "Contract No.");
        end else
            if "Contract Expiration Date" < CurrentDate then
                Error(Text021, "Service Item No.", "Contract No.");
    end;

    procedure CreditMemoBaseExists() Result: Boolean
    var
        ServContractMgt: Codeunit ServContractManagement;
        CreditAmount: Decimal;
        FirstPrepaidPostingDate: Date;
        LastIncomePostingDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreditMemoBaseExists(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Line Amount" > 0 then begin
            TestField("Contract Expiration Date");
            if "Invoiced to Date" >= "Contract Expiration Date" then begin
                Currency.InitRoundingPrecision();
                if ServContractHeader.Prepaid then
                    FirstPrepaidPostingDate := ServContractMgt.FindFirstPrepaidTransaction("Contract No.")
                else
                    FirstPrepaidPostingDate := 0D;
                LastIncomePostingDate := "Invoiced to Date";
                if FirstPrepaidPostingDate <> 0D then
                    LastIncomePostingDate := FirstPrepaidPostingDate - 1;
                CreditAmount :=
                  Round(
                    ServContractMgt.CalcContractLineAmount("Line Amount",
                      "Contract Expiration Date", LastIncomePostingDate),
                    Currency."Amount Rounding Precision");
                if FirstPrepaidPostingDate <> 0D then
                    if "Contract Expiration Date" < FirstPrepaidPostingDate then
                        CreditAmount :=
                          Round(
                            ServContractMgt.CalcContractLineAmount("Line Amount",
                              FirstPrepaidPostingDate, "Invoiced to Date"),
                            Currency."Amount Rounding Precision")
                    else
                        CreditAmount :=
                          Round(
                            ServContractMgt.CalcContractLineAmount("Line Amount",
                              "Contract Expiration Date", "Invoiced to Date"),
                            Currency."Amount Rounding Precision");
            end;
            exit((CreditAmount > 0) and (not Credited));
        end;

        exit(false);
    end;

    procedure LogContractLineChanges(ServContractLine2: Record "Service Contract Line")
    begin
        if "Item No." <> ServContractLine2."Item No." then
            ContractChangeLog.LogContractChange(
              "Contract No.", 1, FieldCaption("Item No."), 0,
              Format(ServContractLine2."Item No."), Format("Item No."),
              ServContractLine2."Service Item No.", "Line No.");

        if "Line Value" <> ServContractLine2."Line Value" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 1, FieldCaption("Line Value"), 0,
              Format(ServContractLine2."Line Value"), Format("Line Value"),
              ServContractLine2."Service Item No.", "Line No.");

        if "Line Discount %" <> ServContractLine2."Line Discount %" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 1, FieldCaption("Line Discount %"), 0,
              Format(ServContractLine2."Line Discount %"), Format("Line Discount %"),
              ServContractLine2."Service Item No.", "Line No.");

        if "Line Amount" <> ServContractLine2."Line Amount" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 1, FieldCaption("Line Amount"), 0,
              Format(ServContractLine2."Line Amount"), Format("Line Amount"),
              ServContractLine2."Service Item No.", "Line No.");

        if "Contract Expiration Date" <> ServContractLine2."Contract Expiration Date" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 1, FieldCaption("Contract Expiration Date"), 0,
              Format(ServContractLine2."Contract Expiration Date"), Format("Contract Expiration Date"),
              ServContractLine2."Service Item No.", "Line No.");

        if "Service Item No." <> ServContractLine2."Service Item No." then
            ContractChangeLog.LogContractChange(
              "Contract No.", 1, FieldCaption("Service Item No."), 0,
              Format(ServContractLine2."Service Item No."), Format("Service Item No."),
              ServContractLine2."Service Item No.", "Line No.");

        OnAfterLogContractLineChanges(Rec, ServContractLine2);
    end;

    procedure SelectMultipleServiceItems()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceItemListPage: Page "Service Item List";
        SelectionFilter: Text;
    begin
        OnBeforeSelectMultipleServiceItems(Rec);

        GetServContractHeader();
        SelectionFilter := ServiceItemListPage.SelectServiceItemsForServiceContract(ServiceContractHeader, Rec);

        if SelectionFilter <> '' then
            AddServiceItems(SelectionFilter);

        OnAfterSelectMultipleServiceItems(Rec);
    end;

    local procedure AddServiceItems(SelectionFilter: Text)
    var
        ServiceItem: Record "Service Item";
        ServiceContractLine: Record "Service Contract Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddServiceItems(Rec, SelectionFilter, IsHandled);
        if IsHandled then
            exit;

        InitNewLine(ServiceContractLine);
        ServiceContractLine.HideDialogBox(true);
        ServiceItem.SetLoadFields("No.");
        ServiceItem.SetFilter("No.", SelectionFilter);
        if ServiceItem.FindSet() then
            repeat
                AddServiceItem(ServiceContractLine, ServiceItem."No.");
            until ServiceItem.Next() = 0;
    end;

    local procedure AddServiceItem(var ServiceContractLine: Record "Service Contract Line"; ServiceItemNo: Code[20])
    begin
        ServiceContractLine."Line No." += 10000;
        ServiceContractLine.Validate("Service Item No.", ServiceItemNo);
        ServiceContractLine.Insert(true);
    end;

    local procedure InitNewLine(var NewServiceContractLine: Record "Service Contract Line")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        NewServiceContractLine.Copy(Rec);
        ServiceContractLine.SetRange("Contract Type", NewServiceContractLine."Contract Type");
        ServiceContractLine.SetRange("Contract No.", NewServiceContractLine."Contract No.");
        if ServiceContractLine.FindLast() then
            NewServiceContractLine."Line No." := ServiceContractLine."Line No."
        else
            NewServiceContractLine."Line No." := 0;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalculateNextServiceVisit(ServContractHeader: Record "Service Contract Header"; ServMgtSetup: Record "Service Mgt. Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetServiceItem(ServiceContractLine: Record "Service Contract Line"; var ServiceItem: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogContractLineChanges(var ServiceContractLine: Record "Service Contract Line"; xServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestStatusOpen(ServiceContractLine: Record "Service Contract Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckServContractHeader(ServContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckCreditMemoDate(var ServiceContractLine: Record "Service Contract Line"; xServiceContractLine: Record "Service Contract Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreditMemoBaseExists(ServiceContractLine: Record "Service Contract Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateContractExpirationDate(var ServiceContractLine: Record "Service Contract Line"; var xServiceContractLine: Record "Service Contract Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineAmount(var ServiceContractLine: Record "Service Contract Line"; var xServiceContractLine: Record "Service Contract Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineDiscountPercent(var ServiceContractLine: Record "Service Contract Line"; var xServiceContractLine: Record "Service Contract Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOtherLineAmountsOnAfterSetFilters(var ServiceContractLine: Record "Service Contract Line")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnUpdateContractAnnualAmountOnAfterGetServContractHeader(var ServiceContractLine: Record "Service Contract Line"; ServContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnAfterCalcServiceItemNoIsNotEmpty(var ServiceContractLine: Record "Service Contract Line"; var ServiceItemNoIsNotEmpty: Boolean; xServiceContractLine: Record "Service Contract Line"; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnBeforeCheckSameItemExist(var ServiceContractLine: Record "Service Contract Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnAfterServContractLineSetFiltersWithContractStatus(var ServiceContractLine: Record "Service Contract Line"; var ServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnBeforeCheckSameCustomer(ServItem: Record "Service Item"; var ServContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateServiceItemNoOnBeforeModify(ServItem: Record "Service Item"; ServContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateServiceItemNoOnAfterInit(var ServContractLineRec: Record "Service Contract Line"; ServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateServiceItemNoOnBeforeOnValidate(var ServiceContractLine: Record "Service Contract Line"; xServiceContractLine: Record "Service Contract Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateServiceItemNoOnBeforeCheckServContractHeaderStatus(var ServiceContractLine: Record "Service Contract Line"; xServiceContractLine: Record "Service Contract Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupNewLine(var ServiceContractLine: Record "Service Contract Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateNextServiceVisit(var ServiceContractLine: Record "Service Contract Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectMultipleServiceItems(var ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectMultipleServiceItems(var ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddServiceItems(var ServiceContractLine: Record "Service Contract Line"; SelectionFilter: Text; var IsHandled: Boolean)
    begin
    end;
}

