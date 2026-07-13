// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

/// <summary>
/// Temporary buffer table that accumulates deferral posting entries before they are written to G/L Entry.
/// Consolidates multiple deferral lines with identical posting parameters into single G/L entries.
/// </summary>
table 1706 "Deferral Posting Buffer"
{
    Caption = 'Deferral Posting Buffer';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique sequential identifier for each buffer entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Source type of the deferred item (G/L Account, Item, Resource, Fixed Asset).
        /// </summary>
        field(2; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Prepmt. Exch. Rate Difference,G/L Account,Item,Resource,Fixed Asset';
            OptionMembers = "Prepmt. Exch. Rate Difference","G/L Account",Item,Resource,"Fixed Asset";
        }
        /// <summary>
        /// G/L Account number for posting the deferral entry.
        /// Must be a posting account that is not blocked.
        /// </summary>
        field(3; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = "G/L Account" where("Account Type" = const(Posting),
                                                 Blocked = const(false));
        }
        /// <summary>
        /// General Business Posting Group for VAT and tax calculations.
        /// </summary>
        field(4; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// General Product Posting Group for VAT and tax calculations.
        /// </summary>
        field(5; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// VAT Business Posting Group for VAT calculation and posting.
        /// </summary>
        field(6; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT Product Posting Group for VAT calculation and posting.
        /// </summary>
        field(7; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Tax Area Code for sales tax calculations in North American localization.
        /// </summary>
        field(8; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Tax Group Code for sales tax calculations in North American localization.
        /// </summary>
        field(9; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Indicates whether the entry is subject to sales tax.
        /// </summary>
        field(10; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether the entry is subject to use tax.
        /// </summary>
        field(11; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Project number for job-related deferral entries.
        /// </summary>
        field(12; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = SystemMetadata;
            TableRelation = Job;
        }
        /// <summary>
        /// Date when this deferral entry will be posted to the G/L.
        /// </summary>
        field(13; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Deferral amount in document currency to be posted to G/L.
        /// </summary>
        field(14; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Deferral amount in local currency (LCY) to be posted to G/L.
        /// </summary>
        field(15; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether this entry was created automatically by the system.
        /// </summary>
        field(16; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Global Dimension 1 code from the source document for reporting and analysis.
        /// </summary>
        field(17; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Global Dimension 2 code from the source document for reporting and analysis.
        /// </summary>
        field(18; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Description of the deferral entry for identification and reporting.
        /// </summary>
        field(19; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// G/L Account used for the temporary deferral balance.
        /// </summary>
        field(20; "Deferral Account"; Code[20])
        {
            Caption = 'Deferral Account';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Period-specific description for the deferral entry.
        /// </summary>
        field(21; "Period Description"; Text[100])
        {
            Caption = 'Period Description';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Type of source document that generated this deferral buffer entry.
        /// </summary>
        field(22; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Document number from the source document.
        /// </summary>
        field(23; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Original sales or purchase amount in document currency before deferral.
        /// </summary>
        field(24; "Sales/Purch Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Sales/Purch Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Original sales or purchase amount in local currency (LCY) before deferral.
        /// </summary>
        field(25; "Sales/Purch Amount (LCY)"; Decimal)
        {
            Caption = 'Sales/Purch Amount (LCY)';
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// General posting type (Purchase or Sale) for proper G/L entry classification.
        /// </summary>
        field(26; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether this represents a partial deferral of the original amount.
        /// </summary>
        field(27; "Partial Deferral"; Boolean)
        {
            Caption = 'Partial Deferral';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Dimension Set ID containing all dimension values for this deferral entry.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        /// <summary>
        /// Deferral template code that generated this buffer entry.
        /// </summary>
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            DataClassification = SystemMetadata;
            TableRelation = "Deferral Template"."Deferral Code";
        }
        /// <summary>
        /// Line number from the deferral schedule that generated this buffer entry.
        /// </summary>
        field(1701; "Deferral Line No."; Integer)
        {
            Caption = 'Deferral Line No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Deferral Doc. Type", "Document No.", "Deferral Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Prepares the deferral posting buffer for sales line posting.
    /// Initializes buffer fields with sales line dimensions and tax information.
    /// </summary>
    /// <param name="SalesLine">Sales line containing the deferral information</param>
    /// <param name="DocumentNo">Document number for the posting</param>
    procedure PrepareSales(SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        Clear(Rec);
        Type := SalesLine.Type.AsInteger();
        "System-Created Entry" := true;
        "Global Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SalesLine."Dimension Set ID";
        "Job No." := SalesLine."Job No.";

        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Sales Tax" then begin
            "Tax Area Code" := SalesLine."Tax Area Code";
            "Tax Group Code" := SalesLine."Tax Group Code";
            "Tax Liable" := SalesLine."Tax Liable";
            "Use Tax" := false;
        end;
        "Deferral Code" := SalesLine."Deferral Code";
        "Deferral Doc. Type" := Enum::"Deferral Document Type"::Sales;
        "Document No." := DocumentNo;

        OnAfterPrepareSales(Rec, SalesLine);
    end;

    /// <summary>
    /// Reverses the signs of all amount fields in the posting buffer.
    /// Used for credit transactions and corrections.
    /// </summary>
    procedure ReverseAmounts()
    begin
        Amount := -Amount;
        "Amount (LCY)" := -"Amount (LCY)";
        "Sales/Purch Amount" := -"Sales/Purch Amount";
        "Sales/Purch Amount (LCY)" := -"Sales/Purch Amount (LCY)";
    end;

    /// <summary>
    /// Prepares the deferral posting buffer for purchase line posting.
    /// Initializes buffer fields with purchase line dimensions and tax information.
    /// </summary>
    /// <param name="PurchLine">Purchase line containing the deferral information</param>
    /// <param name="DocumentNo">Document number for the posting</param>
    procedure PreparePurch(PurchLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        Clear(Rec);
        Type := PurchLine.Type.AsInteger();
        "System-Created Entry" := true;
        "Global Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PurchLine."Dimension Set ID";
        "Job No." := PurchLine."Job No.";

        if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" then begin
            "Tax Area Code" := PurchLine."Tax Area Code";
            "Tax Group Code" := PurchLine."Tax Group Code";
            "Tax Liable" := PurchLine."Tax Liable";
            "Use Tax" := false;
        end;
        "Deferral Code" := PurchLine."Deferral Code";
        "Deferral Doc. Type" := Enum::"Deferral Document Type"::Purchase;
        "Document No." := DocumentNo;

        OnAfterPreparePurch(Rec, PurchLine);
    end;

    local procedure PrepareRemainderAmounts(NewAmountLCY: Decimal; NewAmount: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20])
    begin
        "Amount (LCY)" := 0;
        Amount := 0;
        "Sales/Purch Amount (LCY)" := NewAmountLCY;
        "Sales/Purch Amount" := NewAmount;
        "G/L Account" := GLAccount;
        "Deferral Account" := DeferralAccount;
        "Partial Deferral" := true;
    end;

    /// <summary>
    /// Prepares the deferral posting buffer for remainder sales amounts.
    /// Handles partial deferrals where only part of the line amount is deferred.
    /// </summary>
    /// <param name="SalesLine">Sales line containing the deferral information</param>
    /// <param name="NewAmountLCY">LCY amount for the remainder</param>
    /// <param name="NewAmount">Amount for the remainder</param>
    /// <param name="GLAccount">G/L account for posting</param>
    /// <param name="DeferralAccount">Deferral account for posting</param>
    /// <param name="DeferralLineNo">Line number for the deferral</param>
    procedure PrepareRemainderSales(SalesLine: Record "Sales Line"; NewAmountLCY: Decimal; NewAmount: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20]; DeferralLineNo: Integer)
    begin
        PrepareRemainderAmounts(NewAmountLCY, NewAmount, GLAccount, DeferralAccount);
        "Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := SalesLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := SalesLine."VAT Prod. Posting Group";
        "Gen. Posting Type" := "Gen. Posting Type"::Sale;
        "Deferral Line No." := DeferralLineNo;

        OnAfterPrepareRemainderSales(Rec, SalesLine);
    end;

    /// <summary>
    /// Prepares the deferral posting buffer for remainder purchase amounts.
    /// Handles partial deferrals where only part of the line amount is deferred.
    /// </summary>
    /// <param name="PurchaseLine">Purchase line containing the deferral information</param>
    /// <param name="NewAmountLCY">LCY amount for the remainder</param>
    /// <param name="NewAmount">Amount for the remainder</param>
    /// <param name="GLAccount">G/L account for posting</param>
    /// <param name="DeferralAccount">Deferral account for posting</param>
    /// <param name="DeferralLineNo">Line number for the deferral</param>
    procedure PrepareRemainderPurchase(PurchaseLine: Record "Purchase Line"; NewAmountLCY: Decimal; NewAmount: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20]; DeferralLineNo: Integer)
    begin
        PrepareRemainderAmounts(NewAmountLCY, NewAmount, GLAccount, DeferralAccount);
        "Gen. Bus. Posting Group" := PurchaseLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := PurchaseLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := PurchaseLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := PurchaseLine."VAT Prod. Posting Group";
        "Gen. Posting Type" := "Gen. Posting Type"::Purchase;
        "Deferral Line No." := DeferralLineNo;

        OnAfterPrepareRemainderPurchase(Rec, PurchaseLine);
    end;

    /// <summary>
    /// Prepares initial amounts for deferral posting buffer.
    /// Overload method without discount parameters.
    /// </summary>
    /// <param name="AmountLCY">LCY amount</param>
    /// <param name="AmountACY">ACY amount</param>
    /// <param name="RemainAmtToDefer">Remaining amount to defer</param>
    /// <param name="RemainAmtToDeferACY">Remaining ACY amount to defer</param>
    /// <param name="GLAccount">G/L account for posting</param>
    /// <param name="DeferralAccount">Deferral account for posting</param>
    procedure PrepareInitialAmounts(AmountLCY: Decimal; AmountACY: decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20])
    begin
        PrepareInitialAmounts(AmountLCY, AmountACY, RemainAmtToDefer, RemainAmtToDeferACY, GLAccount, DeferralAccount, 0, 0);
    end;

    /// <summary>
    /// Prepares initial amounts for deferral posting buffer including discount handling.
    /// Extended version with discount amount parameters.
    /// </summary>
    /// <param name="AmountLCY">LCY amount</param>
    /// <param name="AmountACY">ACY amount</param>
    /// <param name="RemainAmtToDefer">Remaining amount to defer</param>
    /// <param name="RemainAmtToDeferACY">Remaining ACY amount to defer</param>
    /// <param name="GLAccount">G/L account for posting</param>
    /// <param name="DeferralAccount">Deferral account for posting</param>
    /// <param name="DiscountAmount">Discount amount to consider</param>
    /// <param name="DiscountAmountACY">ACY discount amount to consider</param>
    procedure PrepareInitialAmounts(AmountLCY: Decimal; AmountACY: decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20]; DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    var
        NewAmountLCY: Decimal;
        NewAmount: Decimal;
    begin
        if (RemainAmtToDefer <> 0) or (RemainAmtToDeferACY <> 0) then begin
            NewAmountLCY := RemainAmtToDefer;
            NewAmount := RemainAmtToDeferACY;
        end else begin
            NewAmountLCY := AmountLCY - DiscountAmount;
            NewAmount := AmountACY - DiscountAmountACY;
        end;
        PrepareRemainderAmounts(NewAmountLCY, NewAmount, DeferralAccount, GLAccount);
        "Amount (LCY)" := NewAmountLCY;
        Amount := NewAmount;
    end;

    /// <summary>
    /// Initializes the posting buffer from a deferral line record.
    /// Copies amounts, dates, and description from the deferral line.
    /// </summary>
    /// <param name="DeferralLine">Deferral line to copy data from</param>
    procedure InitFromDeferralLine(DeferralLine: Record "Deferral Line")
    begin
        "Amount (LCY)" := DeferralLine."Amount (LCY)";
        Amount := DeferralLine.Amount;
        "Sales/Purch Amount (LCY)" := DeferralLine."Amount (LCY)";
        "Sales/Purch Amount" := DeferralLine.Amount;
        "Posting Date" := DeferralLine."Posting Date";
        Description := DeferralLine.Description;
    end;

    /// <summary>
    /// Updates an existing deferral posting buffer record with values from another buffer.
    /// Accumulates amounts if a matching record exists, otherwise creates a new record.
    /// </summary>
    /// <param name="DeferralPostBuffer">Source buffer containing the values to add</param>
    procedure Update(DeferralPostBuffer: Record "Deferral Posting Buffer")
    begin
        SetRange(Type, DeferralPostBuffer.Type);
        SetRange("G/L Account", DeferralPostBuffer."G/L Account");
        SetRange("Gen. Bus. Posting Group", DeferralPostBuffer."Gen. Bus. Posting Group");
        SetRange("Gen. Prod. Posting Group", DeferralPostBuffer."Gen. Prod. Posting Group");
        SetRange("VAT Bus. Posting Group", DeferralPostBuffer."VAT Bus. Posting Group");
        SetRange("VAT Prod. Posting Group", DeferralPostBuffer."VAT Prod. Posting Group");
        SetRange("Tax Area Code", DeferralPostBuffer."Tax Area Code");
        SetRange("Tax Group Code", DeferralPostBuffer."Tax Group Code");
        SetRange("Tax Liable", DeferralPostBuffer."Tax Liable");
        SetRange("Use Tax", DeferralPostBuffer."Use Tax");
        SetRange("Dimension Set ID", DeferralPostBuffer."Dimension Set ID");
        SetRange("Job No.", DeferralPostBuffer."Job No.");
        SetRange("Deferral Code", DeferralPostBuffer."Deferral Code");
        SetRange("Posting Date", DeferralPostBuffer."Posting Date");
        SetRange("Partial Deferral", DeferralPostBuffer."Partial Deferral");
        SetRange("Deferral Line No.", DeferralPostBuffer."Deferral Line No.");
        OnUpdateOnAfterSetFilters(Rec, DeferralPostBuffer);
        if FindFirst() then begin
            Amount += DeferralPostBuffer.Amount;
            "Amount (LCY)" += DeferralPostBuffer."Amount (LCY)";
            "Sales/Purch Amount" += DeferralPostBuffer."Sales/Purch Amount";
            "Sales/Purch Amount (LCY)" += DeferralPostBuffer."Sales/Purch Amount (LCY)";
            if not DeferralPostBuffer."System-Created Entry" then
                "System-Created Entry" := false;
            if IsCombinedDeferralZero() then
                Delete()
            else
                Modify();
        end else begin
            Rec := DeferralPostBuffer;
            "Entry No." := GetLastEntryNo() + 1;
            OnUpdateOnBeforeDeferralPostBufferInsert(Rec, DeferralPostBuffer);
            Insert();
        end;
    end;

    local procedure IsCombinedDeferralZero(): Boolean
    begin
        if (Amount = 0) and ("Amount (LCY)" = 0) and
           ("Sales/Purch Amount" = 0) and ("Sales/Purch Amount (LCY)" = 0)
        then
            exit(true);

        exit(false);
    end;

    /// <summary>
    /// Gets the last entry number used in the deferral posting buffer table.
    /// Used for assigning sequential entry numbers to new buffer records.
    /// </summary>
    /// <returns>The highest entry number currently in use</returns>
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    /// <summary>
    /// Integration event raised after preparing deferral posting buffer for sales line processing.
    /// Enables custom field updates or additional processing after sales line preparation.
    /// </summary>
    /// <param name="DeferralPostingBuffer">Deferral posting buffer record prepared for sales</param>
    /// <param name="SalesLine">Source sales line record used for preparation</param>
    /// <remarks>
    /// Raised from PrepareSales procedure after standard sales line preparation logic.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareSales(var DeferralPostingBuffer: Record "Deferral Posting Buffer"; SalesLine: Record "Sales Line");
    begin
    end;

    /// <summary>
    /// Integration event raised after preparing deferral posting buffer for purchase line processing.
    /// Enables custom field updates or additional processing after purchase line preparation.
    /// </summary>
    /// <param name="DeferralPostingBuffer">Deferral posting buffer record prepared for purchase</param>
    /// <param name="PurchaseLine">Source purchase line record used for preparation</param>
    /// <remarks>
    /// Raised from PreparePurch procedure after standard purchase line preparation logic.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPreparePurch(var DeferralPostingBuffer: Record "Deferral Posting Buffer"; PurchaseLine: Record "Purchase Line");
    begin
    end;


    /// <summary>
    /// Integration event raised after setting filters on deferral posting buffer during update operation.
    /// Enables custom filter modification or additional processing on filtered records.
    /// </summary>
    /// <param name="DeferralPostingBufferRec">Deferral posting buffer record with filters applied</param>
    /// <param name="DeferralPostBuffer">Source deferral posting buffer for filter context</param>
    /// <remarks>
    /// Raised from Update procedure after applying standard filters for buffer updates.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateOnAfterSetFilters(var DeferralPostingBufferRec: Record "Deferral Posting Buffer"; DeferralPostBuffer: Record "Deferral Posting Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting deferral posting buffer record during update operation.
    /// Enables custom field updates or validation before buffer record insertion.
    /// </summary>
    /// <param name="ToDeferralPostingBuffer">Target deferral posting buffer record to be inserted</param>
    /// <param name="FromDeferralPostingBuffer">Source deferral posting buffer record for data copying</param>
    /// <remarks>
    /// Raised from Update procedure before inserting new deferral posting buffer entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateOnBeforeDeferralPostBufferInsert(var ToDeferralPostingBuffer: Record "Deferral Posting Buffer"; FromDeferralPostingBuffer: Record "Deferral Posting Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised after preparing remainder deferral posting buffer for purchase processing.
    /// Enables custom processing of remainder amounts for purchase transactions.
    /// </summary>
    /// <param name="DeferralPostingBuffer">Deferral posting buffer record prepared for purchase remainder</param>
    /// <param name="PurchaseLine">Source purchase line record for remainder calculation</param>
    /// <remarks>
    /// Raised from PrepareRemainderPurchase procedure after calculating purchase remainder amounts.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareRemainderPurchase(var DeferralPostingBuffer: Record "Deferral Posting Buffer"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after preparing remainder deferral posting buffer for sales processing.
    /// Enables custom processing of remainder amounts for sales transactions.
    /// </summary>
    /// <param name="DeferralPostingBuffer">Deferral posting buffer record prepared for sales remainder</param>
    /// <param name="SalesLine">Source sales line record for remainder calculation</param>
    /// <remarks>
    /// Raised from PrepareRemainderSales procedure after calculating sales remainder amounts.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareRemainderSales(var DeferralPostingBuffer: Record "Deferral Posting Buffer"; SalesLine: Record "Sales Line")
    begin
    end;
}